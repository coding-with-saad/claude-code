# Minikube Local Development Workflow

## Quick Reference

```bash
# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Switch Docker to Minikube's daemon
eval $(minikube docker-env)

# Build images in Minikube
docker build -t <service>:latest -f <path>/Dockerfile .

# Create secrets
kubectl create secret generic <app>-secrets -n <namespace> --from-literal=KEY=value

# Deploy with Helm
helm install <app> ./helm/<app> -n <namespace> -f values-local.yaml

# Get service URLs
minikube service <service-name> -n <namespace> --url

# Check status
kubectl get pods -n <namespace>
kubectl logs -f -l app.kubernetes.io/name=<app> -n <namespace>
```

## Initial Setup

### Prerequisites

Install required tools:

```bash
# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Docker (varies by OS)
# See https://docs.docker.com/get-docker/
```

### Start Minikube Cluster

```bash
# Start with appropriate resources
minikube start --driver=docker --cpus=2 --memory=4096

# Verify cluster is running
minikube status

# Check Kubernetes version
kubectl version --short
```

**Driver options**:
- `docker` (recommended): Uses Docker containers
- `virtualbox`: Uses VirtualBox VMs
- `kvm2`: Uses KVM on Linux
- `hyperkit`: Uses Hyperkit on macOS

**Resource sizing**:
- **Small app** (1-2 services): `--cpus=2 --memory=2048`
- **Medium app** (3-5 services): `--cpus=2 --memory=4096` (recommended)
- **Large app** (6+ services): `--cpus=4 --memory=8192`

## Image Build Strategy

### Option 1: Build in Minikube's Docker Daemon (Recommended)

**Workflow**:

```bash
# 1. Switch Docker client to Minikube's daemon
eval $(minikube docker-env)

# 2. Build images (images go directly into Minikube)
docker build -t service1:latest -f services/service1/Dockerfile .
docker build -t service2:latest -f services/service2/Dockerfile .

# 3. Verify images exist in Minikube
docker images | grep service

# 4. Deploy to Kubernetes (images already available)
helm install myapp ./helm/myapp
```

**Advantages**:
- **Fast iteration**: 5-10s build time, no transfer overhead
- **Persistent images**: Images survive Minikube restarts
- **Familiar workflow**: Same `docker build` commands as usual
- **No registry needed**: Images built and consumed locally

**Disadvantages**:
- **Terminal session specific**: Need to run `eval $(minikube docker-env)` in each shell
- **Minikube-only**: Pattern doesn't work for cloud Kubernetes

**When to use**: Local development with frequent code changes

### Option 2: Load Images from Host Docker

**Workflow**:

```bash
# 1. Build images on host Docker
docker build -t service1:latest -f services/service1/Dockerfile .

# 2. Load into Minikube
minikube image load service1:latest

# 3. Deploy to Kubernetes
helm install myapp ./helm/myapp
```

**Advantages**:
- **No environment switching**: Use host Docker normally
- **CI/CD friendly**: Works in automated pipelines

**Disadvantages**:
- **Slow transfer**: 20-40s per image
- **Not persistent**: Images lost on Minikube restart
- **Extra step**: Must reload images after each build

**When to use**: CI/CD pipelines, infrequent builds

### Option 3: Local Docker Registry

**Setup**:

```bash
# Start local registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Configure Minikube to use it
minikube start --insecure-registry="host.docker.internal:5000"
```

**Workflow**:

```bash
# Build and push to local registry
docker build -t localhost:5000/service1:latest .
docker push localhost:5000/service1:latest

# Deploy from registry
helm install myapp ./helm/myapp
```

**Advantages**:
- **Production-like**: Mimics real registry workflow
- **Multi-environment**: Can share images across clusters

**Disadvantages**:
- **Complex setup**: Registry configuration and management
- **Network overhead**: Push/pull operations
- **Over-engineering**: Unnecessary for simple local dev

**When to use**: Testing registry integration, multi-cluster setups

## imagePullPolicy Configuration

Set in Deployment templates or Helm values:

```yaml
# Recommended for Minikube
imagePullPolicy: IfNotPresent

# Alternative options
imagePullPolicy: Always   # Always pull from registry (slow, use for prod)
imagePullPolicy: Never    # Never pull, fail if missing (dangerous)
```

**IfNotPresent behavior**:
1. Check if image exists locally in Minikube
2. If yes: Use local image
3. If no: Try to pull from registry
4. If registry pull fails: Pod fails to start

**Best practice**: Use `IfNotPresent` in values.yaml, override to `Always` in production

## Development Iteration Cycle

### Fast Iteration Workflow

**Typical cycle time: 15-30 seconds**

```bash
# 1. Make code changes
vim src/app.py

# 2. Rebuild image in Minikube's daemon
eval $(minikube docker-env)
docker build -t myservice:latest -f services/myservice/Dockerfile .

# 3. Restart pods to pick up new image
kubectl rollout restart deployment/myservice -n myapp

# 4. Watch pod restart
kubectl get pods -n myapp -w

# 5. Check logs
kubectl logs -f -l app=myservice -n myapp
```

### Image Caching Optimization

**Problem**: Docker builds from scratch every time

**Solution**: Multi-stage builds with layer caching

```dockerfile
# Stage 1: Dependencies (rarely changes)
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Build (changes frequently)
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Runtime
FROM node:18-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/main.js"]
```

**Benefits**: Dependencies cached, only rebuild changed layers

### Force Image Refresh

If Kubernetes doesn't pick up new image:

```bash
# Option 1: Restart deployment
kubectl rollout restart deployment/myservice -n myapp

# Option 2: Delete and recreate pod
kubectl delete pod -l app=myservice -n myapp

# Option 3: Redeploy with Helm
helm upgrade myapp ./helm/myapp -n myapp
```

## Service Access Patterns

### NodePort (External Access)

**Use for**: User-facing services (web UIs, APIs)

```yaml
# Service manifest
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  ports:
  - port: 3000        # ClusterIP port
    targetPort: 3000  # Container port
    nodePort: 30000   # External port (30000-32767)
  selector:
    app: frontend
```

**Access service**:

```bash
# Get service URL
minikube service frontend --url
# Returns: http://192.168.49.2:30000

# Open in browser
minikube service frontend
```

**NodePort ranges**:
- **30000-30099**: User-facing services
- **30100-30199**: Internal tools (monitoring, admin)
- **30200+**: Other services

### ClusterIP (Internal Only)

**Use for**: Internal services (databases, APIs, workers)

```yaml
# Service manifest
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  type: ClusterIP  # Default, can be omitted
  ports:
  - port: 8000
    targetPort: 8000
  selector:
    app: api
```

**Access service** (from within cluster):

```yaml
# From another pod
http://api:8000/endpoint
http://api.namespace.svc.cluster.local:8000/endpoint
```

**Access service** (from host for debugging):

```bash
# Port-forward to access from localhost
kubectl port-forward svc/api 8000:8000 -n myapp

# Now accessible at http://localhost:8000
curl http://localhost:8000/health
```

## Secret Management Workflow

### Create Secrets Before Deployment

```bash
# Create namespace first
kubectl create namespace myapp

# Create secret with multiple keys
kubectl create secret generic myapp-secrets \
  --namespace=myapp \
  --from-literal=DATABASE_URL='postgresql://user:pass@host:5432/db' \
  --from-literal=API_KEY='sk-your-api-key-here' \
  --from-literal=AUTH_SECRET='your-32-character-secret'

# Verify secret created
kubectl get secret myapp-secrets -n myapp
kubectl describe secret myapp-secrets -n myapp
```

### Alternative: From File

```bash
# Create .env.secrets (DO NOT commit to git)
cat > .env.secrets <<EOF
DATABASE_URL=postgresql://user:pass@host:5432/db
API_KEY=sk-your-api-key-here
AUTH_SECRET=your-32-character-secret
EOF

# Create secret from file
kubectl create secret generic myapp-secrets \
  --namespace=myapp \
  --from-env-file=.env.secrets

# Clean up file
rm .env.secrets
```

### Update Secrets

```bash
# Delete old secret
kubectl delete secret myapp-secrets -n myapp

# Create new secret
kubectl create secret generic myapp-secrets \
  --namespace=myapp \
  --from-literal=DATABASE_URL='new-value'

# Restart pods to pick up new secret
kubectl rollout restart deployment -n myapp
```

## Troubleshooting

### Minikube Won't Start

```bash
# Check status
minikube status

# Delete and recreate cluster
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096

# Check logs
minikube logs
```

### Images Not Found (ImagePullBackOff)

```bash
# Verify you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Check images exist
docker images | grep myservice

# If missing, rebuild
docker build -t myservice:latest -f services/myservice/Dockerfile .

# Verify imagePullPolicy
kubectl describe pod <pod-name> -n myapp | grep "Image Pull Policy"
# Should show: IfNotPresent
```

### Pods CrashLoopBackOff

```bash
# Check pod events
kubectl describe pod <pod-name> -n myapp

# Check logs (current)
kubectl logs <pod-name> -n myapp

# Check logs (previous crash)
kubectl logs <pod-name> -n myapp --previous

# Common causes:
# - Missing secrets
# - Wrong environment variables
# - Health check failures
# - Application errors
```

### Service Not Accessible

```bash
# Check service exists
kubectl get svc -n myapp

# Check endpoints (should list pod IPs)
kubectl get endpoints -n myapp

# If no endpoints, pods aren't ready
kubectl get pods -n myapp

# For NodePort services
minikube service <service-name> -n myapp --url

# For ClusterIP services
kubectl port-forward svc/<service-name> 8000:8000 -n myapp
```

### Reset Docker Environment

If you need to switch back to host Docker:

```bash
# Reset Docker environment variables
eval $(minikube docker-env -u)

# Verify using host Docker
docker images
# Should show host images, not Minikube images
```

## Cleanup

### Partial Cleanup (Keep Cluster)

```bash
# Uninstall Helm release
helm uninstall myapp -n myapp

# Delete namespace (removes all resources)
kubectl delete namespace myapp
```

### Full Cleanup

```bash
# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete

# Remove all Minikube data
rm -rf ~/.minikube
```

## Performance Tuning

### Resource Limits

Check pod resource usage:

```bash
# Enable metrics server
minikube addons enable metrics-server

# View resource usage
kubectl top pods -n myapp
kubectl top nodes
```

Adjust based on usage:

```yaml
# In Helm values.yaml
resources:
  requests:
    cpu: 100m      # Guaranteed CPU
    memory: 128Mi  # Guaranteed memory
  limits:
    cpu: 200m      # Maximum CPU
    memory: 256Mi  # Maximum memory
```

### Minikube Performance

```bash
# Increase resources
minikube stop
minikube start --cpus=4 --memory=8192

# Use faster driver
minikube start --driver=kvm2  # Linux only
```

## Best Practices

### DO

- ✅ Use `eval $(minikube docker-env)` for fast iteration
- ✅ Set `imagePullPolicy: IfNotPresent` for local images
- ✅ Create secrets before deploying
- ✅ Use NodePort for external services, ClusterIP for internal
- ✅ Allocate sufficient resources (2 CPU, 4GB memory minimum)
- ✅ Use Helm for repeatable deployments
- ✅ Check pod logs for errors

### DON'T

- ❌ Use `imagePullPolicy: Always` in local dev (slow)
- ❌ Commit secrets to values.yaml
- ❌ Forget to run `eval $(minikube docker-env)` in new shells
- ❌ Use `latest` tag in production (use specific versions)
- ❌ Run Minikube in production (cloud Kubernetes instead)
- ❌ Ignore resource limits (can crash Minikube)
