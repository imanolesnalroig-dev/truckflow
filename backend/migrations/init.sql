-- TruckFlow Database Schema
-- Requires: PostgreSQL 16+ with PostGIS and TimescaleDB extensions

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "timescaledb";

-- Users (drivers)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  password_hash VARCHAR(255),
  display_name VARCHAR(100),
  language VARCHAR(5) DEFAULT 'en',
  country VARCHAR(2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  reputation_score INTEGER DEFAULT 0,
  total_km_driven DECIMAL(12,2) DEFAULT 0,
  total_reports INTEGER DEFAULT 0,
  total_reviews INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Truck profiles (a user can have multiple trucks)
CREATE TABLE IF NOT EXISTS truck_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100),
  height_cm INTEGER,
  weight_kg INTEGER,
  length_cm INTEGER,
  width_cm INTEGER DEFAULT 260,
  axle_count INTEGER DEFAULT 5,
  axle_weight_kg INTEGER DEFAULT 10000,
  has_trailer BOOLEAN DEFAULT true,
  trailer_type VARCHAR(50),
  hazmat_class VARCHAR(20),
  emission_class VARCHAR(10),
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_truck_profiles_user ON truck_profiles(user_id);

-- GPS telemetry (TimescaleDB hypertable)
CREATE TABLE IF NOT EXISTS gps_pings (
  time TIMESTAMPTZ NOT NULL,
  user_id UUID NOT NULL,
  truck_profile_id UUID,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  speed_kmh DECIMAL(6,2),
  heading DECIMAL(5,2),
  accuracy_m DECIMAL(6,2),
  is_moving BOOLEAN,
  activity_state VARCHAR(20)
);

-- Convert to hypertable (skip if already exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM timescaledb_information.hypertables
    WHERE hypertable_name = 'gps_pings'
  ) THEN
    PERFORM create_hypertable('gps_pings', 'time');
  END IF;
END $$;

-- Compression policy
ALTER TABLE gps_pings SET (timescaledb.compress, timescaledb.compress_segmentby = 'user_id');

-- Add compression policy (compress after 7 days)
SELECT add_compression_policy('gps_pings', INTERVAL '7 days', if_not_exists => true);

-- Retention policy (keep raw pings for 90 days)
SELECT add_retention_policy('gps_pings', INTERVAL '90 days', if_not_exists => true);

CREATE INDEX IF NOT EXISTS idx_gps_pings_user_time ON gps_pings(user_id, time DESC);

-- Community hazard reports
CREATE TABLE IF NOT EXISTS hazard_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  hazard_type VARCHAR(50) NOT NULL,
  subtype VARCHAR(50),
  description TEXT,
  severity VARCHAR(20) DEFAULT 'medium',
  direction DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  confirmed_count INTEGER DEFAULT 1,
  denied_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  road_name VARCHAR(255),
  country VARCHAR(2)
);

CREATE INDEX IF NOT EXISTS idx_hazard_location ON hazard_reports USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_hazard_active ON hazard_reports(is_active, expires_at);

-- Warehouse / loading point locations
CREATE TABLE IF NOT EXISTS locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  google_place_id VARCHAR(255),
  name VARCHAR(255) NOT NULL,
  address TEXT,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  location_type VARCHAR(50),
  country VARCHAR(2),
  avg_waiting_time_min INTEGER,
  avg_rating DECIMAL(3,2),
  total_reviews INTEGER DEFAULT 0,
  ai_summary TEXT,
  ai_summary_updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_location_geo ON locations USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_location_type ON locations(location_type);

-- Location reviews
CREATE TABLE IF NOT EXISTS location_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 5),
  waiting_time_rating INTEGER CHECK (waiting_time_rating BETWEEN 1 AND 5),
  access_rating INTEGER CHECK (access_rating BETWEEN 1 AND 5),
  staff_rating INTEGER CHECK (staff_rating BETWEEN 1 AND 5),
  facilities_rating INTEGER CHECK (facilities_rating BETWEEN 1 AND 5),
  actual_waiting_time_min INTEGER,
  scheduled_time_slot TIMESTAMPTZ,
  mega_trailer_ok BOOLEAN,
  has_truck_parking BOOLEAN,
  has_toilets BOOLEAN,
  has_water BOOLEAN,
  requires_ppe BOOLEAN,
  ppe_details VARCHAR(255),
  comment TEXT,
  language VARCHAR(5),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  visit_date DATE,
  verified BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_reviews_location ON location_reviews(location_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON location_reviews(user_id);

-- Truck parking locations
CREATE TABLE IF NOT EXISTS truck_parks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255),
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  address TEXT,
  country VARCHAR(2),
  total_spaces INTEGER,
  has_security BOOLEAN DEFAULT false,
  has_camera BOOLEAN DEFAULT false,
  has_fence BOOLEAN DEFAULT false,
  has_electricity BOOLEAN DEFAULT false,
  has_water BOOLEAN DEFAULT false,
  has_toilets BOOLEAN DEFAULT false,
  has_showers BOOLEAN DEFAULT false,
  has_restaurant BOOLEAN DEFAULT false,
  has_shop BOOLEAN DEFAULT false,
  has_adblue BOOLEAN DEFAULT false,
  has_wifi BOOLEAN DEFAULT false,
  current_occupancy_pct DECIMAL(5,2),
  last_occupancy_update TIMESTAMPTZ,
  avg_rating DECIMAL(3,2),
  total_reviews INTEGER DEFAULT 0,
  price_per_night_eur DECIMAL(8,2),
  is_free BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_truck_park_geo ON truck_parks USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_truck_park_country ON truck_parks(country);

-- Driving time tracking (EC 561/2006 compliance)
CREATE TABLE IF NOT EXISTS driving_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  total_driving_min INTEGER,
  total_break_min INTEGER,
  distance_km DECIMAL(10,2),
  session_type VARCHAR(20) DEFAULT 'daily',
  is_compliant BOOLEAN DEFAULT true,
  violations JSONB
);

CREATE INDEX IF NOT EXISTS idx_driving_sessions_user ON driving_sessions(user_id, started_at DESC);

-- Map data corrections (crowdsourced)
CREATE TABLE IF NOT EXISTS map_corrections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  correction_type VARCHAR(50),
  osm_way_id BIGINT,
  reported_value VARCHAR(100),
  official_value VARCHAR(100),
  confidence_score DECIMAL(3,2) DEFAULT 0.5,
  confirmed_by_count INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'pending'
);

CREATE INDEX IF NOT EXISTS idx_corrections_location ON map_corrections USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_corrections_status ON map_corrections(status);

-- Insert some sample truck parking data (Poland for MVP testing)
INSERT INTO truck_parks (name, location, address, country, total_spaces, has_security, has_toilets, has_wifi, is_free)
VALUES
  ('Autohof Gorzyczki', ST_SetSRID(ST_MakePoint(18.3831, 49.9344), 4326)::geography, 'Gorzyczki, Poland', 'PL', 80, true, true, true, false),
  ('MOP Tuszyn', ST_SetSRID(ST_MakePoint(19.5306, 51.6103), 4326)::geography, 'A1 Highway, Tuszyn', 'PL', 120, true, true, false, false),
  ('Shell Strykow', ST_SetSRID(ST_MakePoint(19.6003, 51.8981), 4326)::geography, 'A2 Highway, Strykow', 'PL', 60, false, true, true, false)
ON CONFLICT DO NOTHING;

-- Create function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_locations_updated_at ON locations;
CREATE TRIGGER update_locations_updated_at
  BEFORE UPDATE ON locations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
