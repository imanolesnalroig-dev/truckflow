# TruckFlow

**Free Waze-style truck navigation for European FTL drivers**

TruckFlow provides truck-legal routing, driving time compliance tracking, community hazard reporting, and AI-powered warehouse reviews - completely free for drivers.

## Architecture

```
truckflow/
├── mobile/          # Flutter app (Android + iOS)
├── backend/         # Node.js/TypeScript API
├── routing/         # Valhalla routing engine config
└── docker-compose.yml
```

## Tech Stack

- **Mobile**: Flutter + Mapbox + Riverpod
- **Backend**: Node.js + TypeScript + Fastify
- **Database**: PostgreSQL + PostGIS + TimescaleDB
- **Routing**: Valhalla (self-hosted)
- **AI**: Google Gemini API
- **Infrastructure**: Google Cloud (Cloud Run + Cloud SQL)

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 20+
- Flutter 3.16+
- Google Cloud CLI

### Local Development

```bash
# Start all services
docker-compose up -d

# Backend development
cd backend
npm install
npm run dev

# Mobile development
cd mobile
flutter pub get
flutter run
```

### Environment Variables

Copy `.env.example` to `.env` and fill in:

```
DATABASE_URL=postgres://truckflow:dev_password@localhost:5432/truckflow
REDIS_URL=redis://localhost:6379
KAFKA_BROKERS=localhost:9092
VALHALLA_URL=http://localhost:8002
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_PLACES_API_KEY=your_places_api_key
JWT_SECRET=your_jwt_secret
```

## Features

### MVP (Phase 1)
- [x] Truck-legal routing (height, weight, length restrictions)
- [x] Turn-by-turn navigation
- [x] Background GPS collection
- [x] Driving time compliance (EC 561/2006)
- [x] Community hazard reporting
- [x] Warehouse/loading point reviews with AI summaries
- [x] Truck parking finder
- [x] 8 languages (PL, RO, DE, ES, EN, BG, LT, TR)

### Phase 2
- [ ] iOS app
- [ ] Live traffic from user data
- [ ] Fuel price comparison
- [ ] Border crossing wait times
- [ ] Gamification

### Phase 3 (B2B)
- [ ] Supply heatmap dashboard
- [ ] FTL pricing prediction engine
- [ ] Data API for TMS integration

## License

Proprietary - All rights reserved
# Auto-deployed via Cloud Build
