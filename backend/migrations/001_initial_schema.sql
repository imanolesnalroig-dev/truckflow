-- TruckFlow Database Schema
-- Requires PostgreSQL 15+ with PostGIS and TimescaleDB extensions

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  language CHAR(2) DEFAULT 'en',
  country CHAR(2),
  is_active BOOLEAN DEFAULT true,
  reputation_score INTEGER DEFAULT 0,
  total_km_driven DECIMAL(12,2) DEFAULT 0,
  total_reports INTEGER DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- Truck profiles
CREATE TABLE truck_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  height_cm INTEGER NOT NULL,
  weight_kg INTEGER NOT NULL,
  length_cm INTEGER NOT NULL,
  width_cm INTEGER DEFAULT 260,
  axle_count INTEGER DEFAULT 5,
  axle_weight_kg INTEGER DEFAULT 10000,
  has_trailer BOOLEAN DEFAULT true,
  trailer_type VARCHAR(20), -- tilt, reefer, mega, tank, flatbed, container, other
  hazmat_class VARCHAR(20),
  emission_class VARCHAR(10), -- euro3, euro4, euro5, euro6, euro6d
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_truck_profiles_user ON truck_profiles(user_id);

-- Locations (warehouses, factories, distribution centers)
CREATE TABLE locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  address TEXT,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  location_type VARCHAR(50), -- warehouse, factory, distribution_center, port, etc
  google_place_id VARCHAR(255),
  avg_waiting_time_min DECIMAL(6,2),
  avg_rating DECIMAL(3,2),
  total_reviews INTEGER DEFAULT 0,
  ai_summary TEXT,
  ai_summary_updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_locations_geo ON locations USING GIST(location);
CREATE INDEX idx_locations_type ON locations(location_type);

-- Location reviews
CREATE TABLE location_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  overall_rating INTEGER NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
  waiting_time_rating INTEGER CHECK (waiting_time_rating >= 1 AND waiting_time_rating <= 5),
  access_rating INTEGER CHECK (access_rating >= 1 AND access_rating <= 5),
  staff_rating INTEGER CHECK (staff_rating >= 1 AND staff_rating <= 5),
  facilities_rating INTEGER CHECK (facilities_rating >= 1 AND facilities_rating <= 5),
  actual_waiting_time_min INTEGER,
  mega_trailer_ok BOOLEAN,
  has_truck_parking BOOLEAN,
  has_toilets BOOLEAN,
  has_water BOOLEAN,
  requires_ppe BOOLEAN,
  ppe_details VARCHAR(255),
  comment TEXT,
  language CHAR(2) DEFAULT 'en',
  visit_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_location_reviews_location ON location_reviews(location_id);
CREATE INDEX idx_location_reviews_user ON location_reviews(user_id);

-- Hazard reports (community-reported road hazards)
CREATE TABLE hazard_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  hazard_type VARCHAR(50) NOT NULL, -- police, accident, road_closure, construction, road_hazard, weather, border_delay
  subtype VARCHAR(50),
  description TEXT,
  severity VARCHAR(20) DEFAULT 'medium', -- low, medium, high, critical
  direction INTEGER, -- 0-360 degrees
  is_active BOOLEAN DEFAULT true,
  confirmed_count INTEGER DEFAULT 0,
  denied_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_hazard_reports_geo ON hazard_reports USING GIST(location);
CREATE INDEX idx_hazard_reports_active ON hazard_reports(is_active, expires_at);
CREATE INDEX idx_hazard_reports_type ON hazard_reports(hazard_type);

-- Driving sessions (EC 561/2006 compliance tracking)
CREATE TABLE driving_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  total_driving_min DECIMAL(8,2),
  total_break_min DECIMAL(8,2) DEFAULT 0,
  distance_km DECIMAL(10,2) DEFAULT 0,
  is_compliant BOOLEAN DEFAULT true,
  violations JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_driving_sessions_user ON driving_sessions(user_id);
CREATE INDEX idx_driving_sessions_active ON driving_sessions(user_id, ended_at) WHERE ended_at IS NULL;
CREATE INDEX idx_driving_sessions_date ON driving_sessions(user_id, started_at);

-- Truck parks (secure parking areas)
CREATE TABLE truck_parks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  address TEXT,
  country CHAR(2),
  location GEOGRAPHY(POINT, 4326) NOT NULL,
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
  current_occupancy_pct INTEGER,
  last_occupancy_update TIMESTAMPTZ,
  avg_rating DECIMAL(3,2),
  total_reviews INTEGER DEFAULT 0,
  price_per_night_eur DECIMAL(6,2),
  is_free BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_truck_parks_geo ON truck_parks USING GIST(location);
CREATE INDEX idx_truck_parks_country ON truck_parks(country);

-- GPS pings (for TimescaleDB - high-frequency time-series data)
-- Note: This table should be converted to a hypertable after creation
CREATE TABLE gps_pings (
  time TIMESTAMPTZ NOT NULL,
  user_id UUID NOT NULL,
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  speed_kmh DECIMAL(5,1),
  heading INTEGER,
  accuracy_m DECIMAL(6,1)
);

-- Create hypertable for GPS pings if TimescaleDB is available
-- SELECT create_hypertable('gps_pings', 'time', if_not_exists => TRUE);

CREATE INDEX idx_gps_pings_user_time ON gps_pings(user_id, time DESC);
