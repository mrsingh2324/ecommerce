# 🎯 Setup Checklist

Use this checklist to track your setup progress. Check off each item as you complete it.

## Phase 1: Pre-requisites

- [ ] Google Cloud Platform account created
- [ ] Billing enabled on GCP project
- [ ] `gcloud` CLI installed and authenticated
- [ ] `kubectl` installed
- [ ] Docker installed and running
- [ ] Git configured
- [ ] Java 17+ installed
- [ ] Maven 3.8+ installed
- [ ] GitHub account with repository created

## Phase 2: GCP Initial Setup

- [ ] Project ID decided: `___________________________`
- [ ] Region decided (e.g., us-central1): `___________________________`
- [ ] Logged into GCP: `gcloud auth login`
- [ ] Set project: `gcloud config set project YOUR-PROJECT-ID`

### Environment Variables Set

```bash
export PROJECT_ID="___________________________"  # Fill this in
export REGION="us-central1"
export CLUSTER_NAME="ecommerce-cluster"
export REPO_NAME="ecommerce-repo"
```

- [ ] Environment variables exported

## Phase 3: Enable GCP APIs

Run these commands:

```bash
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

- [ ] Container API enabled
- [ ] Artifact Registry API enabled
- [ ] Compute Engine API enabled
- [ ] Cloud Resource Manager API enabled

## Phase 4: Create Artifact Registry

```bash
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="E-commerce microservices repository"

gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

- [ ] Artifact Registry created
- [ ] Docker authentication configured
- [ ] Registry name noted: `___________________________`

## Phase 5: Create GKE Cluster

```bash
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

gcloud container clusters get-credentials $CLUSTER_NAME --zone=${REGION}-a
```

- [ ] GKE cluster created (takes 5-10 minutes)
- [ ] Cluster credentials obtained
- [ ] `kubectl` connected to cluster (verify with `kubectl get nodes`)

## Phase 6: Service Account Setup

```bash
# Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account"

# Set email variable
export SA_EMAIL="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"

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

# Create key
gcloud iam service-accounts keys create key.json \
    --iam-account=$SA_EMAIL
```

- [ ] Service account created
- [ ] Permissions granted
- [ ] Key file `key.json` created
- [ ] Key content copied (use `cat key.json`)

**⚠️ IMPORTANT: Keep key.json secure and never commit it to Git!**

## Phase 7: GitHub Repository Setup

- [ ] Repository created on GitHub
- [ ] Local repository cloned
- [ ] Remote origin set to your repository

## Phase 8: GitHub Secrets Configuration

Go to: `Your Repo` → `Settings` → `Secrets and variables` → `Actions`

Create these secrets:

- [ ] `GCP_PROJECT_ID` = `___________________________` (your project ID)
- [ ] `GCP_SA_KEY` = (paste entire contents of key.json)
- [ ] `GKE_CLUSTER_NAME` = `ecommerce-cluster`
- [ ] `GKE_ZONE` = `us-central1-a`
- [ ] `GCP_REGION` = `us-central1`
- [ ] `ARTIFACT_REGISTRY_REPO` = `ecommerce-repo`

## Phase 9: Update Configuration Files

### Update Kubernetes Manifests

Replace `YOUR-PROJECT-ID` with your actual project ID in these files:

```bash
# Quick command
find k8s/ -name "*-deployment.yaml" -type f -exec sed -i "s/YOUR-PROJECT-ID/${PROJECT_ID}/g" {} \;
```

Files to verify:
- [ ] `k8s/product-service-deployment.yaml`
- [ ] `k8s/order-service-deployment.yaml`
- [ ] `k8s/api-gateway-deployment.yaml`

### Verify GitHub Actions Workflow

- [ ] Check `.github/workflows/ci-cd-pipeline.yml` uses secrets correctly

## Phase 10: Initial Deployment

### Manual Deployment (Recommended First Time)

```bash
# Create namespace
kubectl create namespace ecommerce

# Apply all manifests
kubectl apply -f k8s/ -n ecommerce

# Check status
kubectl get pods -n ecommerce
kubectl get svc -n ecommerce
```

- [ ] Namespace created
- [ ] All manifests applied
- [ ] Pods are running (1/1 Ready)
- [ ] Services created

### Or GitHub Actions Deployment

```bash
git add .
git commit -m "Initial setup"
git push origin main
```

- [ ] Code pushed to GitHub
- [ ] GitHub Actions workflow triggered
- [ ] Workflow completed successfully
- [ ] Check Actions tab for status

## Phase 11: Verify Deployment

```bash
# Get services
kubectl get svc -n ecommerce

# Get external IP
kubectl get svc api-gateway -n ecommerce
```

- [ ] API Gateway has external IP: `___________________________`
- [ ] External IP is accessible

### Test Endpoints

```bash
# Test health
curl http://YOUR-EXTERNAL-IP/actuator/health

# Test routes
curl http://YOUR-EXTERNAL-IP/actuator/gateway/routes

# Test services
curl http://YOUR-EXTERNAL-IP/api/products
curl http://YOUR-EXTERNAL-IP/api/orders
```

- [ ] Health endpoint responds
- [ ] Gateway routes configured
- [ ] Product service accessible
- [ ] Order service accessible

## Phase 12: Enable Auto-Deployment (Optional)

- [ ] Uncomment deployment section in `.github/workflows/ci-cd-pipeline.yml`
- [ ] Push changes
- [ ] Verify auto-deployment works

## Phase 13: Documentation

- [ ] Document your external IP
- [ ] Update any service-specific configuration
- [ ] Note any custom changes made
- [ ] Share access with team members (if applicable)

## 🎉 Completion Checklist

- [ ] All services running
- [ ] External IP accessible
- [ ] API endpoints responding
- [ ] GitHub Actions pipeline working
- [ ] Monitoring endpoints accessible
- [ ] Documentation complete

## 📝 Important Information to Save

| Item | Value |
|------|-------|
| GCP Project ID | `___________________________` |
| GCP Region | `___________________________` |
| Cluster Name | `___________________________` |
| Cluster Zone | `___________________________` |
| Artifact Registry | `___________________________` |
| External IP | `___________________________` |
| Namespace | `ecommerce` |

## 🔄 Next Steps

After completing setup:

1. **Customize Services**: Modify services for your use case
2. **Add Features**: Implement business logic
3. **Security**: Add authentication/authorization
4. **Monitoring**: Set up Prometheus/Grafana
5. **Logging**: Configure centralized logging
6. **Scaling**: Adjust HPA settings
7. **Database**: Replace H2 with production database
8. **CI/CD**: Enhance pipeline with testing

## 🆘 Need Help?

If stuck at any step:
1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review [README.md](README.md) detailed instructions
3. Check GKE logs: `kubectl logs -n ecommerce <pod-name>`
4. Verify GCP quotas: Console → IAM & Admin → Quotas
5. Check GitHub Actions logs in Actions tab

---

**Good luck with your deployment! 🚀**
