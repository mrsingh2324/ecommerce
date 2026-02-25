# E-Commerce Microservices - GKE Deployment Template

A production-ready microservices architecture template for e-commerce applications with CI/CD pipeline using GitHub Actions and Google Kubernetes Engine (GKE).

## 🏗️ Architecture

This template includes:
- **API Gateway** (Spring Cloud Gateway) - Port 8080
- **Product Service** - Port 8081
- **Order Service** - Port 8082

## 📋 Prerequisites

Before starting, ensure you have:

1. **Google Cloud Platform Account**
   - Active GCP project
   - Billing enabled

2. **Tools Installed**
   - `gcloud` CLI
   - `kubectl`
   - Docker
   - Git
   - Java 17+
   - Maven 3.8+

3. **GitHub Account**
   - Repository with GitHub Actions enabled

## 🚀 Quick Start Guide

### Step 1: Clone and Setup Repository

```bash
# Clone this template
git clone <your-repo-url>
cd ecommerce-microservices-template

# Create your own repository on GitHub
# Push this template to your repository
git remote set-url origin <your-new-repo-url>
git push -u origin main
```

### Step 2: Google Cloud Setup

#### 2.1 Set Environment Variables

```bash
# Set your project details
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export CLUSTER_NAME="ecommerce-cluster"
export REPO_NAME="ecommerce-repo"
```

#### 2.2 Enable Required APIs

```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

#### 2.3 Create Artifact Registry

```bash
# Create Docker repository
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="E-commerce microservices repository"

# Configure Docker authentication
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

#### 2.4 Create GKE Cluster

```bash
# Create GKE cluster
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

# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone=${REGION}-a
```

### Step 3: GitHub Secrets Setup

Add the following secrets to your GitHub repository:

#### 3.1 Navigate to GitHub Secrets
1. Go to your repository on GitHub
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**

#### 3.2 Create Service Account and Key

```bash
# Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account"

# Get service account email
export SA_EMAIL="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create key.json \
    --iam-account=$SA_EMAIL

# Display the key (copy this entire output)
cat key.json
```

#### 3.3 Required GitHub Secrets

Add these secrets with values specific to your setup:

| Secret Name | Value | How to Get |
|------------|-------|-----------|
| `GCP_PROJECT_ID` | your-gcp-project-id | From GCP Console or `gcloud config get-value project` |
| `GCP_SA_KEY` | Service account JSON key | Output from `cat key.json` above |
| `GKE_CLUSTER_NAME` | ecommerce-cluster | Your cluster name |
| `GKE_ZONE` | us-central1-a | Your cluster zone |
| `GCP_REGION` | us-central1 | Your region |
| `ARTIFACT_REGISTRY_REPO` | ecommerce-repo | Your artifact registry name |

### Step 4: Update Configuration Files

#### 4.1 Update GitHub Actions Workflow

Edit `.github/workflows/ci-cd-pipeline.yml`:

```yaml
env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}              # ✅ Already configured via secrets
  GKE_CLUSTER: ${{ secrets.GKE_CLUSTER_NAME }}          # ✅ Already configured via secrets
  GKE_ZONE: ${{ secrets.GKE_ZONE }}                     # ✅ Already configured via secrets
  GCP_REGION: ${{ secrets.GCP_REGION }}                 # ✅ Already configured via secrets
  ARTIFACT_REGISTRY: ${{ secrets.ARTIFACT_REGISTRY_REPO }} # ✅ Already configured via secrets
```

#### 4.2 Update Kubernetes Manifests

The deployment files in `k8s/` directory reference Artifact Registry.

**Replace placeholders in each file:**

Files to update:
- `k8s/product-service-deployment.yaml`
- `k8s/order-service-deployment.yaml`
- `k8s/api-gateway-deployment.yaml`

Find and replace:
```yaml
# BEFORE
image: us-central1-docker.pkg.dev/YOUR-PROJECT-ID/ecommerce-repo/product-service:latest

# AFTER (example)
image: us-central1-docker.pkg.dev/cicdcollab/ecommerce-repo/product-service:latest
```

**Quick find & replace command:**
```bash
# Run this in the root directory
export YOUR_PROJECT_ID="your-actual-project-id"

# Update all deployment files
find k8s/ -name "*-deployment.yaml" -type f -exec sed -i "s/YOUR-PROJECT-ID/${YOUR_PROJECT_ID}/g" {} \;
```

### Step 5: Build and Test Locally (Optional)

```bash
# Build all services
./mvnw clean package -DskipTests

# Build Docker images
docker build -t product-service:local ./product-service
docker build -t order-service:local ./order-service
docker build -t api-gateway:local ./api-gateway

# Test locally with docker-compose
docker-compose up -d
```

### Step 6: Deploy to GKE

#### 6.1 Manual Deployment (First Time)

```bash
# Create namespace
kubectl create namespace ecommerce

# Apply all Kubernetes manifests
kubectl apply -f k8s/ -n ecommerce

# Check deployment status
kubectl get pods -n ecommerce
kubectl get svc -n ecommerce
```

#### 6.2 Automated Deployment via GitHub Actions

Simply push to the `main` branch:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will automatically:
1. Build all services
2. Run tests
3. Build Docker images
4. Push to Artifact Registry
5. Deploy to GKE

### Step 7: Access Your Application

```bash
# Get the external IP of API Gateway
kubectl get svc api-gateway -n ecommerce

# Output will show:
# NAME          TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
# api-gateway   LoadBalancer   10.30.5.119    34.136.16.138    80:32755/TCP
```

**Your API endpoints:**
- Health Check: `http://<EXTERNAL-IP>/actuator/health`
- Gateway Routes: `http://<EXTERNAL-IP>/actuator/gateway/routes`
- Product Service: `http://<EXTERNAL-IP>/api/products`
- Order Service: `http://<EXTERNAL-IP>/api/orders`

### Step 8: Enable Auto-Deployment on Push (Optional)

The workflow file includes commented GKE deployment triggers. To enable:

1. Edit `.github/workflows/ci-cd-pipeline.yml`
2. Uncomment the deployment steps under `# Deploy to GKE` section
3. Commit and push

Now every push to `main` will trigger automatic deployment!

## 📁 Project Structure

```
ecommerce-microservices-template/
├── .github/
│   └── workflows/
│       └── ci-cd-pipeline.yml          # GitHub Actions CI/CD pipeline
├── api-gateway/                         # API Gateway service
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── product-service/                     # Product microservice
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── order-service/                       # Order microservice
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── k8s/                                 # Kubernetes manifests
│   ├── namespace.yaml
│   ├── api-gateway-deployment.yaml
│   ├── api-gateway-service.yaml
│   ├── product-service-deployment.yaml
│   ├── product-service-service.yaml
│   ├── order-service-deployment.yaml
│   └── order-service-service.yaml
├── docs/                                # Documentation
│   ├── SETUP.md
│   └── TROUBLESHOOTING.md
├── docker-compose.yml                   # Local development
├── pom.xml                             # Parent POM
├── README.md
└── SETUP_CHECKLIST.md                  # Step-by-step checklist
```

## 🔧 Configuration

### Environment Profiles

Each service supports multiple profiles:
- `dev` - Development (H2 in-memory database)
- `prod` - Production (uses environment variables)
- `kubernetes` - Kubernetes-specific settings

### Service Discovery

Services communicate using Kubernetes DNS:
- Product Service: `http://product-service:8081`
- Order Service: `http://order-service:8082`

### API Gateway Routes

Configured in `api-gateway/src/main/resources/application-kubernetes.yml`:
- `/api/products/**` → Product Service
- `/api/orders/**` → Order Service

## 🧪 Testing

```bash
# Run tests for all services
./mvnw test

# Run tests for specific service
cd product-service
./mvnw test
```

## 📊 Monitoring

Access actuator endpoints:
```bash
# Health check
curl http://<EXTERNAL-IP>/actuator/health

# Metrics
curl http://<EXTERNAL-IP>/actuator/metrics

# Gateway routes
curl http://<EXTERNAL-IP>/actuator/gateway/routes
```

## 🐛 Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n ecommerce
kubectl describe pod <pod-name> -n ecommerce
kubectl logs <pod-name> -n ecommerce
```

### Check Service Endpoints
```bash
kubectl get svc -n ecommerce
kubectl get endpoints -n ecommerce
```

### Check Events
```bash
kubectl get events -n ecommerce --sort-by='.lastTimestamp'
```

### Common Issues

1. **Pods stuck in Pending**: Check node resources
   ```bash
   kubectl describe nodes
   ```

2. **ImagePullBackOff**: Check Artifact Registry permissions
   ```bash
   gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}
   ```

3. **CrashLoopBackOff**: Check application logs
   ```bash
   kubectl logs <pod-name> -n ecommerce --previous
   ```

## 🧹 Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace ecommerce

# Delete GKE cluster
gcloud container clusters delete $CLUSTER_NAME --zone=${REGION}-a

# Delete Artifact Registry
gcloud artifacts repositories delete $REPO_NAME --location=$REGION

# Delete service account
gcloud iam service-accounts delete $SA_EMAIL
```

## 📝 Customization Guide

### Adding a New Microservice

1. Create service directory (e.g., `payment-service/`)
2. Add `pom.xml` and `Dockerfile`
3. Create Kubernetes manifests in `k8s/`
4. Update GitHub Actions workflow
5. Configure API Gateway routes

### Changing Service Ports

1. Update `application.yml` in service
2. Update Kubernetes Service manifest
3. Update deployment health check ports
4. Update API Gateway configuration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Spring Boot & Spring Cloud teams
- Google Kubernetes Engine documentation
- GitHub Actions community

## 📞 Support

For issues and questions:
- Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Open an issue on GitHub
- Review GKE logs: `kubectl logs -n ecommerce <pod-name>`

---

**Happy Coding! 🚀**
