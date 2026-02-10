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

### Environment Variables
**IMPORTANT**: After each Cloud Build deployment, you must manually set the database env vars:
```bash
gcloud run services update truckflow-api --region=europe-west1 --project=truckflow-app \
  --update-env-vars='DATABASE_URL=postgres://postgres:changeme123@/truckflow?host=/cloudsql/truckflow-app:europe-west1:truckflow-db' \
  --update-env-vars='REDIS_URL=redis://10.14.115.203:6379'
```
This is due to Cloud Build's limitations with special characters in env var values.

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
