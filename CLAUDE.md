# TruckFlow Development Guidelines

## Deployment

This project uses CI/CD with GitHub and Cloud Build:

- **Always commit and push changes to `main`** before expecting them in production
- Cloud Build triggers automatically on push to `main`
- Deployment takes 3-5 minutes after push

### Cloud Infrastructure
- **Cloud Run**: `truckflow-api` in `europe-west1`
- **Cloud SQL**: PostgreSQL 15 at `truckflow-app:europe-west1:truckflow-db`
- **Memorystore Redis**: `10.14.115.203:6379` (requires VPC connector)
- **API URL**: https://truckflow-api-794599390333.europe-west1.run.app

### Secrets (Google Secret Manager)
DATABASE_URL and REDIS_URL are stored in Secret Manager and automatically injected at deploy time.
To update a secret:
```bash
echo -n 'new-value' | gcloud secrets versions add SECRET_NAME --data-file=- --project=truckflow-app
```

## Database

### Running Migrations Locally
```bash
# Start Cloud SQL Proxy
./cloud-sql-proxy truckflow-app:europe-west1:truckflow-db --port=5433 &

# Run migration
PGPASSWORD=changeme123 psql -h 127.0.0.1 -p 5433 -U postgres -d truckflow -f backend/migrations/001_initial_schema.sql
```

### Schema Location
- Migrations: `backend/migrations/`
- Current schema: `001_initial_schema.sql`

## Tech Stack

### Backend
- Node.js/TypeScript with Fastify
- PostgreSQL 15 with PostGIS (geospatial)
- Redis for caching
- JWT authentication

### Mobile
- Flutter/Dart
- Mapbox for maps
- Riverpod for state management

## Important Notes

1. The backend gracefully handles missing database/Redis connections - it will log warnings but won't crash
2. EC 561/2006 driving time compliance rules are in `compliance.routes.ts`
3. Valhalla is used for truck routing (not yet deployed)
