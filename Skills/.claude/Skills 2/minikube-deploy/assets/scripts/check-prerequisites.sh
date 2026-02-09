#!/bin/bash
# =============================================================================
# Minikube Deployment Prerequisites Checker
# Cross-platform script to validate all requirements before deployment
# =============================================================================

set -e

# Colors (with fallback for non-color terminals)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

ERRORS=0
WARNINGS=0

ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ERRORS=$((ERRORS + 1)); }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo "========================================"
echo "  Minikube Prerequisites Check"
echo "========================================"
echo ""

# =============================================================================
# 1. Check Required Tools
# =============================================================================
echo "Checking required tools..."

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')
    ok "Docker installed (v$DOCKER_VERSION)"

    if docker info &> /dev/null; then
        ok "Docker daemon is running"
    else
        fail "Docker daemon is not running - start Docker Desktop or docker service"
    fi
else
    fail "Docker is not installed - https://docs.docker.com/get-docker/"
fi

# Minikube
if command -v minikube &> /dev/null; then
    MINIKUBE_VERSION=$(minikube version --short 2>/dev/null || echo "unknown")
    ok "Minikube installed ($MINIKUBE_VERSION)"
else
    fail "Minikube is not installed - https://minikube.sigs.k8s.io/docs/start/"
fi

# kubectl
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || echo "installed")
    ok "kubectl installed ($KUBECTL_VERSION)"
else
    fail "kubectl is not installed - https://kubernetes.io/docs/tasks/tools/"
fi

# Helm
if command -v helm &> /dev/null; then
    HELM_VERSION=$(helm version --short 2>/dev/null | cut -d'+' -f1)
    ok "Helm installed ($HELM_VERSION)"
else
    fail "Helm is not installed - https://helm.sh/docs/intro/install/"
fi

echo ""

# =============================================================================
# 2. Check Minikube Status
# =============================================================================
echo "Checking Minikube cluster..."

MINIKUBE_STATUS=$(minikube status -f '{{.Host}}' 2>/dev/null || echo "NotFound")

case "$MINIKUBE_STATUS" in
    "Running")
        ok "Minikube cluster is running"
        if kubectl cluster-info &> /dev/null; then
            ok "Kubernetes API is accessible"
        else
            warn "Kubernetes API not responding - may need: minikube start"
        fi
        ;;
    "Stopped")
        warn "Minikube cluster exists but is stopped - run: minikube start"
        ;;
    "NotFound"|"")
        info "No Minikube cluster found - will be created on deploy"
        ;;
    *)
        warn "Minikube status: $MINIKUBE_STATUS - may need: minikube delete && minikube start"
        ;;
esac

echo ""

# =============================================================================
# 3. Check Project Structure
# =============================================================================
echo "Checking project structure..."

# Find Dockerfiles
DOCKERFILE_COUNT=$(find . -name "Dockerfile" -o -name "Dockerfile.*" 2>/dev/null | grep -v node_modules | grep -v ".git" | wc -l)

if [ "$DOCKERFILE_COUNT" -gt 0 ]; then
    ok "Found $DOCKERFILE_COUNT Dockerfile(s)"
    find . -name "Dockerfile" -o -name "Dockerfile.*" 2>/dev/null | grep -v node_modules | grep -v ".git" | head -5 | while read -r df; do
        echo "     $df"
    done
else
    fail "No Dockerfiles found - cannot deploy without containerization"
fi

# Check for docker-compose
if ls docker-compose*.yml docker-compose*.yaml compose*.yml 2>/dev/null | head -1 > /dev/null; then
    COMPOSE_FILE=$(ls docker-compose*.yml docker-compose*.yaml compose*.yml 2>/dev/null | head -1)
    ok "Found docker-compose: $COMPOSE_FILE"
else
    info "No docker-compose.yml found - will use Dockerfile detection"
fi

# Check for .env
if [ -f ".env" ]; then
    ok "Found .env file for secrets"
elif [ -f ".env.example" ]; then
    warn "Found .env.example but no .env - run: cp .env.example .env"
else
    info "No .env file found - secrets will need manual configuration"
fi

# Check for existing Helm chart
if [ -d "helm" ]; then
    ok "Found existing helm/ directory"
else
    info "No helm/ directory - will be generated automatically"
fi

echo ""

# =============================================================================
# Summary
# =============================================================================
echo "========================================"
echo "  Summary"
echo "========================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Ready to deploy.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}$WARNINGS warning(s) - deployment may proceed with caution${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s) - fix errors before deploying${NC}"
    exit 1
fi
