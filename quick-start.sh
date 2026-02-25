#!/bin/bash

# E-Commerce Microservices - Quick Start Script
# This script helps you set up and deploy the microservices quickly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  E-Commerce Microservices - Quick Start Setup   ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists gcloud; then
    echo -e "${RED}❌ gcloud CLI not found. Please install it first.${NC}"
    exit 1
fi

if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl not found. Please install it first.${NC}"
    exit 1
fi

if ! command_exists docker; then
    echo -e "${RED}❌ Docker not found. Please install it first.${NC}"
    exit 1
fi

if ! command_exists mvn; then
    echo -e "${RED}❌ Maven not found. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are installed!${NC}"
echo ""

# Get user input
echo -e "${YELLOW}Please provide the following information:${NC}"
echo ""

read -p "Enter your GCP Project ID: " PROJECT_ID
read -p "Enter GCP Region (default: us-central1): " REGION
REGION=${REGION:-us-central1}

read -p "Enter Cluster Name (default: ecommerce-cluster): " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-ecommerce-cluster}

read -p "Enter Artifact Registry name (default: ecommerce-repo): " REPO_NAME
REPO_NAME=${REPO_NAME:-ecommerce-repo}

echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Repository: $REPO_NAME"
echo ""

read -p "Continue with these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Set project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project $PROJECT_ID

# Enable APIs
echo -e "${YELLOW}Enabling required GCP APIs...${NC}"
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
echo -e "${GREEN}✅ APIs enabled${NC}"

# Create Artifact Registry
echo -e "${YELLOW}Creating Artifact Registry...${NC}"
if gcloud artifacts repositories describe $REPO_NAME --location=$REGION >/dev/null 2>&1; then
    echo -e "${YELLOW}Repository already exists, skipping...${NC}"
else
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="E-commerce microservices repository"
    echo -e "${GREEN}✅ Artifact Registry created${NC}"
fi

# Configure Docker
echo -e "${YELLOW}Configuring Docker authentication...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev
echo -e "${GREEN}✅ Docker configured${NC}"

# Update Kubernetes manifests
echo -e "${YELLOW}Updating Kubernetes manifests with your Project ID...${NC}"
find k8s/ -name "*-deployment.yaml" -type f -exec sed -i.bak "s/YOUR-PROJECT-ID/${PROJECT_ID}/g" {} \;
rm k8s/*.bak 2>/dev/null || true
echo -e "${GREEN}✅ Kubernetes manifests updated${NC}"

# Create GKE cluster
echo -e "${YELLOW}Creating GKE cluster (this may take 5-10 minutes)...${NC}"
read -p "Create GKE cluster now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gcloud container clusters create $CLUSTER_NAME \
        --zone=${REGION}-a \
        --num-nodes=3 \
        --machine-type=e2-medium \
        --disk-size=20GB \
        --enable-autoscaling \
        --min-nodes=2 \
        --max-nodes=5 \
        --enable-autorepair \
        --enable-autoupgrade

    # Get credentials
    gcloud container clusters get-credentials $CLUSTER_NAME --zone=${REGION}-a
    echo -e "${GREEN}✅ GKE cluster created and configured${NC}"
else
    echo -e "${YELLOW}Skipping cluster creation${NC}"
fi

# Create service account
echo -e "${YELLOW}Creating service account for GitHub Actions...${NC}"
SA_NAME="github-actions-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SA_EMAIL >/dev/null 2>&1; then
    echo -e "${YELLOW}Service account already exists, skipping...${NC}"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="GitHub Actions Service Account"

    # Grant permissions
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/container.developer"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/artifactregistry.writer"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/storage.admin"

    echo -e "${GREEN}✅ Service account created${NC}"
fi

# Create service account key
echo -e "${YELLOW}Creating service account key...${NC}"
if [ -f "key.json" ]; then
    rm key.json
fi

gcloud iam service-accounts keys create key.json \
    --iam-account=$SA_EMAIL

echo -e "${GREEN}✅ Service account key created${NC}"

# Summary
echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}            Setup Complete!                        ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Add GitHub Secrets:"
echo "   - GCP_PROJECT_ID: $PROJECT_ID"
echo "   - GCP_SA_KEY: (copy contents of key.json)"
echo "   - GKE_CLUSTER_NAME: $CLUSTER_NAME"
echo "   - GKE_ZONE: ${REGION}-a"
echo "   - GCP_REGION: $REGION"
echo "   - ARTIFACT_REGISTRY_REPO: $REPO_NAME"
echo ""
echo "2. Review SETUP_CHECKLIST.md for detailed steps"
echo ""
echo "3. Build and deploy:"
echo "   ./mvnw clean package"
echo "   kubectl apply -f k8s/ -n ecommerce"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Keep key.json secure and do not commit to Git!${NC}"
echo ""
echo "Service account key saved to: key.json"
echo ""
