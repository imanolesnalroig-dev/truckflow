#!/bin/bash
# TruckFlow Deployment Script
# Run this after enabling billing on the GCP project

set -e

PROJECT_ID="truckflow-app"
REGION="europe-west1"

echo "🚀 Deploying TruckFlow to GCP..."

# Set project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "📦 Enabling APIs..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  sqladmin.googleapis.com \
  artifactregistry.googleapis.com \
  redis.googleapis.com \
  secretmanager.googleapis.com

# Create Artifact Registry repository
echo "📦 Creating Artifact Registry..."
gcloud artifacts repositories create truckflow \
  --repository-format=docker \
  --location=$REGION \
  --description="TruckFlow Docker images" \
  --quiet || true

# Create Cloud SQL instance (PostgreSQL with PostGIS)
echo "🗄️ Creating Cloud SQL instance..."
gcloud sql instances create truckflow-db \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=$REGION \
  --root-password=changeme123 \
  --database-flags=cloudsql.enable_pg_cron=on \
  --quiet || echo "Cloud SQL instance may already exist"

# Create database
gcloud sql databases create truckflow \
  --instance=truckflow-db \
  --quiet || true

# Create Redis instance (Memorystore)
echo "🔄 Creating Redis instance..."
gcloud redis instances create truckflow-redis \
  --size=1 \
  --region=$REGION \
  --redis-version=redis_7_0 \
  --quiet || echo "Redis instance may already exist"

# Build and deploy API
echo "🏗️ Building and deploying API..."
cd backend

# Build locally and push
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/truckflow/api:latest .
docker push $REGION-docker.pkg.dev/$PROJECT_ID/truckflow/api:latest

# Get Cloud SQL connection name
SQL_CONNECTION=$(gcloud sql instances describe truckflow-db --format='value(connectionName)')

# Get Redis IP
REDIS_IP=$(gcloud redis instances describe truckflow-redis --region=$REGION --format='value(host)' 2>/dev/null || echo "")

# Deploy to Cloud Run
gcloud run deploy truckflow-api \
  --image=$REGION-docker.pkg.dev/$PROJECT_ID/truckflow/api:latest \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --set-env-vars="NODE_ENV=production" \
  --add-cloudsql-instances=$SQL_CONNECTION

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Set environment variables in Cloud Run:"
echo "   - DATABASE_URL (get from Cloud SQL)"
echo "   - REDIS_URL (from Memorystore)"
echo "   - JWT_SECRET (generate a secure secret)"
echo "   - GEMINI_API_KEY (from Google AI Studio)"
echo ""
echo "2. Run database migrations:"
echo "   Connect to Cloud SQL and run: backend/migrations/init.sql"
echo ""
echo "3. Get your API URL:"
API_URL=$(gcloud run services describe truckflow-api --region=$REGION --format='value(status.url)' 2>/dev/null || echo "Pending...")
echo "   $API_URL"
