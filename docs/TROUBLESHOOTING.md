# Troubleshooting Guide

This guide helps you resolve common issues when deploying the e-commerce microservices to GKE.

## Table of Contents
1. [GCP Setup Issues](#gcp-setup-issues)
2. [Kubernetes Issues](#kubernetes-issues)
3. [Docker/Container Issues](#docker-container-issues)
4. [GitHub Actions Issues](#github-actions-issues)
5. [Application Issues](#application-issues)
6. [Networking Issues](#networking-issues)

---

## GCP Setup Issues

### Issue: `gcloud` command not found
**Symptom:** Terminal doesn't recognize `gcloud` command

**Solution:**
```bash
# Install Google Cloud SDK
# For macOS
brew install --cask google-cloud-sdk

# For Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Verify installation
gcloud version
```

### Issue: Permission denied when creating resources
**Symptom:** `ERROR: (gcloud...) User does not have permission`

**Solution:**
```bash
# Check your account
gcloud auth list

# Login again
gcloud auth login

# Check IAM permissions in GCP Console
# Go to: IAM & Admin → IAM → Check your user permissions
```

### Issue: Project billing not enabled
**Symptom:** `Billing must be enabled for activation of service`

**Solution:**
1. Go to [GCP Console → Billing](https://console.cloud.google.com/billing)
2. Link a billing account to your project
3. Enable billing for the project

### Issue: API not enabled
**Symptom:** `API [servicename.googleapis.com] not enabled`

**Solution:**
```bash
# Enable specific API
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com

# List all enabled APIs
gcloud services list --enabled
```

### Issue: Quota exceeded
**Symptom:** `Quota 'CPUS' exceeded. Limit: X.0`

**Solution:**
1. Go to GCP Console → IAM & Admin → Quotas
2. Filter by service and request quota increase
3. OR reduce resource requests in deployments
4. OR delete unused resources

---

## Kubernetes Issues

### Issue: Pods stuck in `Pending` state
**Symptom:** `kubectl get pods` shows `Pending` status

**Diagnose:**
```bash
kubectl describe pod <pod-name> -n ecommerce
```

**Common Causes & Solutions:**

#### 1. Insufficient Resources
```bash
# Check node resources
kubectl describe nodes

# Solution: Scale down replicas temporarily
kubectl scale deployment product-service --replicas=1 -n ecommerce

# OR increase cluster size
gcloud container clusters resize ecommerce-cluster \
    --num-nodes=5 \
    --zone=us-central1-a
```

#### 2. Image Pull Errors
```bash
# Check events
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# Solution: Configure image pull secrets
kubectl create secret docker-registry gcr-json-key \
    --docker-server=us-central1-docker.pkg.dev \
    --docker-username=_json_key \
    --docker-password="$(cat key.json)" \
    --docker-email=user@example.com \
    -n ecommerce
```

### Issue: Pods in `CrashLoopBackOff`
**Symptom:** Pod restarts repeatedly

**Diagnose:**
```bash
# Check current logs
kubectl logs <pod-name> -n ecommerce

# Check previous container logs
kubectl logs <pod-name> -n ecommerce --previous

# Describe pod for events
kubectl describe pod <pod-name> -n ecommerce
```

**Common Causes:**

#### 1. Application Error
```bash
# Check logs for Java exceptions
kubectl logs <pod-name> -n ecommerce | grep -i error

# Solution: Fix application code or configuration
```

#### 2. Readiness Probe Failing
```bash
# Edit deployment to adjust probe
kubectl edit deployment product-service -n ecommerce

# Increase initialDelaySeconds and adjust thresholds
```

#### 3. Out of Memory
```bash
# Check resource limits
kubectl describe pod <pod-name> -n ecommerce | grep -A 5 "Limits"

# Solution: Increase memory limits
kubectl set resources deployment product-service \
    --limits=memory=1Gi \
    -n ecommerce
```

### Issue: Service has no endpoints
**Symptom:** `kubectl get endpoints -n ecommerce` shows empty ENDPOINTS

**Diagnose:**
```bash
# Check if pods are ready
kubectl get pods -n ecommerce -o wide

# Check service selector
kubectl get svc product-service -n ecommerce -o yaml | grep -A 3 selector

# Check pod labels
kubectl get pods -n ecommerce --show-labels
```

**Solution:**
```bash
# Ensure service selector matches pod labels
# Edit service if needed
kubectl edit svc product-service -n ecommerce
```

### Issue: Cannot delete namespace
**Symptom:** Namespace stuck in `Terminating` state

**Solution:**
```bash
# Force delete namespace
kubectl get namespace ecommerce -o json \
    | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
    | kubectl replace --raw /api/v1/namespaces/ecommerce/finalize -f -
```

---

## Docker/Container Issues

### Issue: Docker build fails
**Symptom:** `docker build` command errors

**Solution:**
```bash
# Check Docker is running
docker ps

# Check Dockerfile syntax
docker build --no-cache -t test-image .

# Build with verbose output
docker build --progress=plain -t test-image .
```

### Issue: Cannot push to Artifact Registry
**Symptom:** `unauthorized: authentication required`

**Solution:**
```bash
# Configure Docker auth
gcloud auth configure-docker us-central1-docker.pkg.dev

# Login to gcloud
gcloud auth login

# Check credentials
gcloud auth application-default print-access-token
```

### Issue: Image not found in registry
**Symptom:** `ImagePullBackOff` with "not found" error

**Diagnose:**
```bash
# List images in registry
gcloud artifacts docker images list \
    us-central1-docker.pkg.dev/YOUR-PROJECT-ID/ecommerce-repo

# Check image tag
gcloud artifacts docker images describe \
    us-central1-docker.pkg.dev/YOUR-PROJECT-ID/ecommerce-repo/product-service:latest
```

**Solution:**
```bash
# Ensure image was pushed successfully
docker push us-central1-docker.pkg.dev/YOUR-PROJECT-ID/ecommerce-repo/product-service:latest

# Update deployment with correct image name
kubectl set image deployment/product-service \
    product-service=us-central1-docker.pkg.dev/YOUR-PROJECT-ID/ecommerce-repo/product-service:latest \
    -n ecommerce
```

---

## GitHub Actions Issues

### Issue: Workflow fails on authentication
**Symptom:** `Error: google-github-actions/auth failed`

**Solution:**
```bash
# Verify service account key
cat key.json | jq .

# Recreate secret in GitHub
# Copy the entire contents of key.json
# Paste into GitHub Secrets as GCP_SA_KEY

# Verify secret is set
# Go to: Repo → Settings → Secrets → Actions
```

### Issue: Workflow cannot push to Artifact Registry
**Symptom:** `unauthorized` or `permission denied`

**Solution:**
```bash
# Check service account permissions
gcloud projects get-iam-policy YOUR-PROJECT-ID \
    --flatten="bindings[].members" \
    --format='table(bindings.role)' \
    --filter="bindings.members:serviceAccount:github-actions-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com"

# Add missing role
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
    --member="serviceAccount:github-actions-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"
```

### Issue: Workflow cannot access GKE cluster
**Symptom:** `ERROR: (gcloud.container.clusters.get-credentials) error`

**Solution:**
```bash
# Add container.developer role
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
    --member="serviceAccount:github-actions-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"
```

### Issue: Maven build fails in GitHub Actions
**Symptom:** Build fails with dependency errors

**Solution:**
1. Check pom.xml for correct dependencies
2. Clear Maven cache in workflow:
```yaml
- name: Clear Maven cache
  run: rm -rf ~/.m2/repository
```
3. Add Maven wrapper if missing:
```bash
mvn -N io.takari:maven:wrapper
```

---

## Application Issues

### Issue: 404 Not Found on API endpoints
**Symptom:** `curl http://EXTERNAL-IP/api/products` returns 404

**Diagnose:**
```bash
# Check gateway routes
curl http://EXTERNAL-IP/actuator/gateway/routes | jq

# Check gateway logs
kubectl logs -l app=api-gateway -n ecommerce
```

**Solution:**
1. Verify routes in `application-kubernetes.yml`
2. Ensure paths match: `/api/products/**`
3. Check backend services are accessible:
```bash
kubectl exec -it <api-gateway-pod> -n ecommerce -- sh
# Inside pod:
wget -O- http://product-service:8081/actuator/health
```

### Issue: Service cannot connect to database
**Symptom:** `Connection refused` or database errors

**Solution:**
1. Check database configuration in application.yml
2. For H2 (development): It's in-memory, should work automatically
3. For external DB: Add connection details as environment variables

### Issue: Health check endpoints failing
**Symptom:** Readiness/Liveness probes failing

**Diagnose:**
```bash
# Check actuator is accessible
kubectl exec <pod-name> -n ecommerce -- wget -O- http://localhost:8081/actuator/health
```

**Solution:**
```bash
# Add actuator dependency to pom.xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

# Enable health endpoints in application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      probes:
        enabled: true
```

---

## Networking Issues

### Issue: LoadBalancer external IP pending
**Symptom:** EXTERNAL-IP shows `<pending>` for long time

**Diagnose:**
```bash
# Check service events
kubectl describe svc api-gateway -n ecommerce

# Check GCP load balancers
gcloud compute forwarding-rules list
```

**Solution:**
```bash
# Wait 2-5 minutes for GCP to provision
# If still pending after 10 minutes:

# Check quotas
gcloud compute project-info describe --project=YOUR-PROJECT-ID

# Try recreating service
kubectl delete svc api-gateway -n ecommerce
kubectl apply -f k8s/api-gateway-service.yaml
```

### Issue: Cannot access service from outside cluster
**Symptom:** `curl http://EXTERNAL-IP` times out

**Diagnose:**
```bash
# Check firewall rules
gcloud compute firewall-rules list

# Check service type
kubectl get svc api-gateway -n ecommerce
```

**Solution:**
```bash
# Ensure service type is LoadBalancer
# Create firewall rule if needed
gcloud compute firewall-rules create allow-gateway \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=gke-ecommerce-cluster

# OR use NodePort as alternative
kubectl patch svc api-gateway -n ecommerce -p '{"spec":{"type":"NodePort"}}'
```

### Issue: Services cannot communicate internally
**Symptom:** Order service cannot reach Product service

**Diagnose:**
```bash
# Test from one pod to another
kubectl exec <order-service-pod> -n ecommerce -- wget -O- http://product-service:8081/actuator/health

# Check DNS resolution
kubectl exec <order-service-pod> -n ecommerce -- nslookup product-service.ecommerce.svc.cluster.local
```

**Solution:**
```bash
# Verify service endpoints
kubectl get endpoints -n ecommerce

# Check network policies (if any)
kubectl get networkpolicies -n ecommerce

# Ensure correct service URLs in environment variables
kubectl set env deployment/order-service \
    PRODUCT_SERVICE_URL=http://product-service:8081 \
    -n ecommerce
```

---

## Quick Diagnostic Commands

```bash
# Overall cluster health
kubectl get all -n ecommerce

# Check pod details
kubectl describe pod <pod-name> -n ecommerce

# View logs
kubectl logs <pod-name> -n ecommerce --tail=100 -f

# Check events
kubectl get events -n ecommerce --sort-by='.lastTimestamp' | tail -20

# Port forward for local testing
kubectl port-forward svc/api-gateway 8080:80 -n ecommerce

# Check resource usage
kubectl top pods -n ecommerce
kubectl top nodes

# Get all resources in namespace
kubectl api-resources --verbs=list --namespaced -o name \
    | xargs -n 1 kubectl get --show-kind --ignore-not-found -n ecommerce
```

---

## Getting Help

If issues persist:

1. **Check GCP Status**: https://status.cloud.google.com
2. **Review logs**: Both application and Kubernetes events
3. **GCP Support**: https://cloud.google.com/support
4. **Stack Overflow**: Tag questions with `google-kubernetes-engine`, `spring-boot`
5. **GitHub Issues**: Check if it's a known issue in the repository

## Useful Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
