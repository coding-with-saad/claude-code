#!/bin/bash
set -e

# {{APP_NAME}} Minikube Cleanup Script
# Removes the {{APP_NAME}} application from Minikube and optionally stops the cluster

echo "🧹 {{APP_NAME}} Minikube Cleanup Script"
echo "================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (customize these)
NAMESPACE="{{APP_NAME}}"

# Helper functions
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

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    error "kubectl is not installed"
fi

if ! command -v helm &> /dev/null; then
    error "helm is not installed"
fi

if ! command -v minikube &> /dev/null; then
    error "minikube is not installed"
fi

# Step 1: Uninstall Helm release
info "Uninstalling Helm release '{{APP_NAME}}'..."
if helm list -n "$NAMESPACE" | grep -q "{{APP_NAME}}"; then
    helm uninstall {{APP_NAME}} -n "$NAMESPACE"
    info "Helm release uninstalled ✓"
else
    warn "Helm release '{{APP_NAME}}' not found, skipping..."
fi
echo ""

# Step 2: Delete namespace (this will delete all resources including secrets)
info "Deleting namespace '$NAMESPACE'..."
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo ""
    warn "This will delete:"
    echo "  - All deployments, services, pods"
    echo "  - All secrets (including {{APP_NAME}}-secrets)"
    echo "  - All configmaps"
    echo "  - The namespace itself"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirmation

    if [ "$confirmation" = "yes" ]; then
        kubectl delete namespace "$NAMESPACE"
        info "Namespace deleted ✓"
    else
        info "Namespace deletion cancelled"
    fi
else
    warn "Namespace '$NAMESPACE' not found, skipping..."
fi
echo ""

# Step 3: Clean up Docker images (optional)
info "Checking for Docker images..."
eval $(minikube docker-env)

# TODO: Add your service image names here
# Example:
# IMAGES=("service1:latest" "service2:latest" "service3:latest")
IMAGES=()

IMAGE_COUNT=0

for image in "${IMAGES[@]}"; do
    if docker images -q "$image" 2> /dev/null; then
        ((IMAGE_COUNT++))
    fi
done

if [ $IMAGE_COUNT -gt 0 ]; then
    echo ""
    warn "Found $IMAGE_COUNT {{APP_NAME}} Docker image(s) in Minikube"
    read -p "Do you want to delete these images? (yes/no): " delete_images

    if [ "$delete_images" = "yes" ]; then
        for image in "${IMAGES[@]}"; do
            if docker images -q "$image" 2> /dev/null; then
                docker rmi "$image" || warn "Failed to delete $image"
                info "Deleted $image"
            fi
        done
    else
        info "Docker images kept"
    fi
fi
echo ""

# Step 4: Stop Minikube (optional)
info "Minikube cluster is still running"
read -p "Do you want to stop the Minikube cluster? (yes/no): " stop_minikube

if [ "$stop_minikube" = "yes" ]; then
    info "Stopping Minikube cluster..."
    minikube stop
    info "Minikube cluster stopped ✓"
else
    info "Minikube cluster left running"
fi
echo ""

# Step 5: Success message
echo "✅ Cleanup Complete!"
echo ""
echo "What was cleaned up:"
echo "  ✓ Helm release '{{APP_NAME}}' uninstalled"
echo "  ✓ Namespace '$NAMESPACE' deleted (if confirmed)"
echo "  ✓ Docker images deleted (if confirmed)"
echo "  ✓ Minikube cluster stopped (if confirmed)"
echo ""
echo "To redeploy: ./scripts/deploy-minikube.sh"
