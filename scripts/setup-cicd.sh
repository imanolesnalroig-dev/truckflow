#!/bin/bash
# Setup CI/CD: GitHub → Cloud Build → Cloud Run

set -e

PROJECT_ID="truckflow-app"
REGION="europe-west1"
REPO_OWNER="imanolesnalroig-dev"
REPO_NAME="truckflow"

echo "🔧 Setting up CI/CD pipeline..."

# Set project
gcloud config set project $PROJECT_ID

# Enable Cloud Build API
gcloud services enable cloudbuild.googleapis.com

# Grant Cloud Build permission to deploy to Cloud Run
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Connect GitHub repository to Cloud Build
echo ""
echo "📎 Connect your GitHub repository:"
echo "   1. Go to: https://console.cloud.google.com/cloud-build/triggers?project=$PROJECT_ID"
echo "   2. Click 'Connect Repository'"
echo "   3. Select 'GitHub (Cloud Build GitHub App)'"
echo "   4. Authenticate and select: $REPO_OWNER/$REPO_NAME"
echo ""

# Create Cloud Build trigger
echo "Creating build trigger..."
gcloud builds triggers create github \
  --name="truckflow-deploy" \
  --repo-owner="$REPO_OWNER" \
  --repo-name="$REPO_NAME" \
  --branch-pattern="^main$" \
  --build-config="backend/cloudbuild.yaml" \
  --description="Deploy TruckFlow API on push to main" \
  2>/dev/null || echo "Note: You may need to connect the repository first via the console."

echo ""
echo "✅ CI/CD setup complete!"
echo ""
echo "Now every push to 'main' branch will:"
echo "  1. Build Docker image"
echo "  2. Push to Artifact Registry"
echo "  3. Deploy to Cloud Run"
echo ""
echo "View builds at: https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"
