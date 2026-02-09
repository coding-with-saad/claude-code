#!/bin/bash
set -e

# {{APP_NAME}} Minikube Deployment Script
# Deploys the {{APP_NAME}} application to a local Minikube cluster using Helm
# Supports optional Dapr integration for event-driven architectures

echo "========================================"
echo "  {{APP_NAME}} Minikube Deployment"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Configuration (customize these)
# =============================================================================
NAMESPACE="{{APP_NAME}}"
SECRET_NAME="{{APP_NAME}}-secrets"
HELM_CHART_PATH="./helm/{{APP_NAME}}"
VALUES_FILE="values-local.yaml"

# Dapr configuration
ENABLE_DAPR=false  # Set to true to enable Dapr
ENABLE_REDIS=false # Set to true if using Redis for Dapr pub/sub or state

# =============================================================================
# Helper functions
# =============================================================================
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# =============================================================================
# Step 1: Check prerequisites
# =============================================================================
step "1/10 - Checking prerequisites..."

if ! command -v minikube &> /dev/null; then
    error "minikube is not installed. Please install it from https://minikube.sigs.k8s.io/docs/start/"
fi

if ! command -v kubectl &> /dev/null; then
    error "kubectl is not installed. Please install it from https://kubernetes.io/docs/tasks/tools/"
fi

if ! command -v helm &> /dev/null; then
    error "helm is not installed. Please install it from https://helm.sh/docs/intro/install/"
fi

if ! command -v docker &> /dev/null; then
    error "docker is not installed. Please install it from https://docs.docker.com/get-docker/"
fi

info "All prerequisites are installed"
echo ""

# =============================================================================
# Step 2: Verify Docker daemon is running
# =============================================================================
step "2/10 - Checking Docker daemon..."
if ! docker ps &> /dev/null; then
    error "Docker daemon is not running. Please start Docker and try again."
fi
info "Docker daemon is running"
echo ""

# =============================================================================
# Step 3: Validate Helm chart path exists
# =============================================================================
step "3/10 - Validating Helm chart..."
if [ ! -d "$HELM_CHART_PATH" ]; then
    error "Helm chart not found at: $HELM_CHART_PATH
Please ensure the Helm chart directory exists before running this script."
fi
info "Helm chart found at $HELM_CHART_PATH"
echo ""

# =============================================================================
# Step 4: Start Minikube if not running
# =============================================================================
step "4/10 - Checking Minikube status..."
if ! minikube status &> /dev/null; then
    info "Starting Minikube cluster..."
    minikube start --driver=docker --cpus=2 --memory=4096
else
    info "Minikube is already running"
fi
echo ""

# =============================================================================
# Step 5: Configure Docker environment for Minikube
# =============================================================================
step "5/10 - Configuring Docker environment..."
eval $(minikube docker-env)
info "Docker environment configured for Minikube"
echo ""

# =============================================================================
# Step 6: Install Dapr (if enabled)
# =============================================================================
if [ "$ENABLE_DAPR" = true ]; then
    step "6/10 - Installing Dapr..."

    if ! kubectl get namespace dapr-system &> /dev/null; then
        info "Adding Dapr Helm repository..."
        helm repo add dapr https://dapr.github.io/helm-charts/
        helm repo update

        info "Installing Dapr on Kubernetes..."
        helm install dapr dapr/dapr \
            --namespace dapr-system \
            --create-namespace \
            --wait
        info "Dapr installed successfully"
    else
        info "Dapr is already installed"
    fi

    # Verify Dapr pods
    kubectl get pods -n dapr-system --no-headers | grep -q "Running" || \
        warn "Some Dapr pods may not be ready yet"
    echo ""
else
    step "6/10 - Skipping Dapr installation (disabled)"
    echo ""
fi

# =============================================================================
# Step 7: Install Redis for Dapr (if enabled)
# =============================================================================
if [ "$ENABLE_DAPR" = true ] && [ "$ENABLE_REDIS" = true ]; then
    step "7/10 - Installing Redis for Dapr..."

    # Create namespace first if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        kubectl create namespace "$NAMESPACE"
    fi

    if ! helm list -n "$NAMESPACE" 2>/dev/null | grep -q "redis"; then
        info "Adding Bitnami Helm repository..."
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo update

        info "Installing Redis..."
        helm install redis bitnami/redis \
            --namespace "$NAMESPACE" \
            --set auth.enabled=false \
            --set architecture=standalone \
            --wait
        info "Redis installed successfully"
    else
        info "Redis is already installed"
    fi
    echo ""
else
    step "7/10 - Skipping Redis installation"
    echo ""
fi

# =============================================================================
# Step 8: Build Docker images
# =============================================================================
step "8/10 - Building Docker images..."

# TODO: Add your image build commands here
# Example:
# info "Building api:latest..."
# docker build -t api:latest -f apps/api/Dockerfile apps/api
#
# info "Building frontend:latest..."
# docker build -t frontend:latest -f apps/frontend/Dockerfile apps/frontend

warn "No images to build (customize the script to add your builds)"
info "Docker images ready"
echo ""

# =============================================================================
# Step 9: Check/Create secrets
# =============================================================================
step "9/10 - Checking secrets..."

# Create namespace first if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    info "Creating namespace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE"
fi

if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    warn "Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'"
    echo ""
    echo "Please create the secret with:"
    echo ""
    echo "kubectl create secret generic $SECRET_NAME \\"
    echo "  --namespace=$NAMESPACE \\"
    echo "  --from-literal=DATABASE_URL='postgresql://...' \\"
    echo "  --from-literal=API_KEY='your-api-key'"
    echo ""
    read -p "Press Enter after creating the secret to continue, or Ctrl+C to exit..."
fi

info "Secret '$SECRET_NAME' exists"
echo ""

# =============================================================================
# Step 10: Deploy with Helm
# =============================================================================
step "10/10 - Deploying with Helm..."
cd "$HELM_CHART_PATH"

# Check if release already exists
if helm list -n "$NAMESPACE" | grep -q "{{APP_NAME}}"; then
    info "Upgrading existing Helm release..."
    helm upgrade {{APP_NAME}} . -n "$NAMESPACE" -f "$VALUES_FILE"
else
    info "Installing new Helm release..."
    helm install {{APP_NAME}} . -n "$NAMESPACE" -f "$VALUES_FILE"
fi

cd - > /dev/null
info "Helm deployment complete"
echo ""

# =============================================================================
# Wait for pods to be ready
# =============================================================================
info "Waiting for pods to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance={{APP_NAME}} -n "$NAMESPACE" --timeout=180s 2>/dev/null || \
    warn "Some pods may not be ready yet. Check status with: kubectl get pods -n $NAMESPACE"
echo ""

# =============================================================================
# Verify Dapr components (if enabled)
# =============================================================================
if [ "$ENABLE_DAPR" = true ]; then
    info "Verifying Dapr components..."
    kubectl get components -n "$NAMESPACE" 2>/dev/null || warn "No Dapr components found"
    echo ""

    info "Dapr sidecar status:"
    kubectl get pods -n "$NAMESPACE" -o custom-columns="POD:.metadata.name,READY:.status.containerStatuses[*].ready,DAPR:.metadata.annotations.dapr\.io/enabled" 2>/dev/null || true
    echo ""
fi

# =============================================================================
# Display status
# =============================================================================
info "Pod status:"
kubectl get pods -n "$NAMESPACE"
echo ""

info "Service status:"
kubectl get svc -n "$NAMESPACE"
echo ""

# =============================================================================
# Success message
# =============================================================================
echo "========================================"
echo "  Deployment Complete!"
echo "========================================"
echo ""

if [ "$ENABLE_DAPR" = true ]; then
    echo "Dapr components installed:"
    echo "  - dapr-operator, dapr-sentry, dapr-sidecar-injector (dapr-system)"
    if [ "$ENABLE_REDIS" = true ]; then
        echo "  - Redis (${NAMESPACE})"
    fi
    echo ""
fi

echo "Next steps:"
echo "  1. Start minikube tunnel (in separate terminal):"
echo "     minikube tunnel"
echo ""
echo "  2. Check logs:"
echo "     kubectl logs -f deployment/{{SERVICE_NAME}} -n $NAMESPACE"
if [ "$ENABLE_DAPR" = true ]; then
echo "     kubectl logs -f deployment/{{SERVICE_NAME}} -n $NAMESPACE -c daprd  # Dapr sidecar"
fi
echo ""
echo "  3. Monitor pods:"
echo "     kubectl get pods -n $NAMESPACE -w"
echo ""
echo "To clean up: ./scripts/cleanup-minikube.sh"
