#!/bin/bash
# TruckFlow Infrastructure Setup
# Run this once to set up GCP infrastructure, then use CI/CD for deployments

set -e

PROJECT_ID="truckflow-app"
REGION="europe-west1"

echo "🚀 Setting up TruckFlow infrastructure on GCP..."

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
  --quiet 2>/dev/null || echo "  ↳ Already exists"

# Create Cloud SQL instance (PostgreSQL)
echo "🗄️ Creating Cloud SQL instance (this takes ~5 minutes)..."
gcloud sql instances create truckflow-db \
  --database-version=POSTGRES_15 \
  --edition=ENTERPRISE \
  --tier=db-f1-micro \
  --region=$REGION \
  --root-password=changeme123 \
  --quiet 2>/dev/null || echo "  ↳ Already exists"

# Create database
echo "🗄️ Creating database..."
gcloud sql databases create truckflow \
  --instance=truckflow-db \
  --quiet 2>/dev/null || echo "  ↳ Already exists"

# Create Redis instance (Memorystore)
echo "🔄 Creating Redis instance (this takes ~5 minutes)..."
gcloud redis instances create truckflow-redis \
  --size=1 \
  --region=$REGION \
  --redis-version=redis_7_0 \
  --quiet 2>/dev/null || echo "  ↳ Already exists"

echo ""
echo "✅ Infrastructure setup complete!"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Set up CI/CD (GitHub → Cloud Build → Cloud Run):"
echo "   chmod +x scripts/setup-cicd.sh && ./scripts/setup-cicd.sh"
echo ""
echo "2. Connect GitHub repo at:"
echo "   https://console.cloud.google.com/cloud-build/triggers?project=$PROJECT_ID"
echo ""
echo "3. After connecting, push to 'main' branch to deploy automatically"
echo ""
echo "4. Set environment secrets in Cloud Run:"
echo "   - DATABASE_URL"
echo "   - REDIS_URL"
echo "   - JWT_SECRET"
echo "   - GEMINI_API_KEY"
