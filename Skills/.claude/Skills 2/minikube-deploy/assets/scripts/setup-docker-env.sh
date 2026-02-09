#!/bin/bash
# =============================================================================
# Cross-Platform Minikube Docker Environment Setup
# Works on: Linux, macOS, Windows (Git Bash, WSL, MSYS2)
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "windows";;
        MINGW*)     echo "windows";;
        MSYS*)      echo "windows";;
        *)          echo "unknown";;
    esac
}

OS=$(detect_os)
info "Detected OS: $OS"

# =============================================================================
# Start Minikube if not running
# =============================================================================
start_minikube() {
    if minikube status &> /dev/null; then
        info "Minikube is already running"
    else
        info "Starting Minikube..."
        minikube start --driver=docker --cpus=2 --memory=4096
    fi
}

# =============================================================================
# Configure Docker Environment
# =============================================================================
configure_docker_env() {
    case "$OS" in
        linux|macos)
            info "Configuring Docker environment for $OS..."
            eval $(minikube docker-env)
            ;;
        windows)
            info "Configuring Docker environment for Windows..."
            # For Git Bash / MSYS2 / Cygwin
            if [ -n "$MSYSTEM" ] || [ -n "$CYGWIN" ]; then
                eval $(minikube docker-env)
            else
                # Fallback: export manually
                export DOCKER_TLS_VERIFY="1"
                export DOCKER_HOST=$(minikube docker-env | grep DOCKER_HOST | cut -d'"' -f2)
                export DOCKER_CERT_PATH=$(minikube docker-env | grep DOCKER_CERT_PATH | cut -d'"' -f2)
                export MINIKUBE_ACTIVE_DOCKERD="minikube"
            fi
            ;;
        *)
            error "Unsupported OS: $OS"
            ;;
    esac
}

# =============================================================================
# Verify Docker Connection
# =============================================================================
verify_docker() {
    info "Verifying Docker connection to Minikube..."
    if docker info &> /dev/null; then
        info "Docker is connected to Minikube"
        echo ""
        echo "Current Docker context:"
        echo "  DOCKER_HOST: $DOCKER_HOST"
        echo "  DOCKER_CERT_PATH: $DOCKER_CERT_PATH"
        echo ""
    else
        error "Failed to connect to Minikube's Docker daemon"
    fi
}

# =============================================================================
# Export for current shell (source this script)
# =============================================================================
export_env_vars() {
    echo ""
    echo "To use in your current shell, run:"
    echo ""
    case "$OS" in
        linux|macos)
            echo "  eval \$(minikube docker-env)"
            ;;
        windows)
            echo "  # For Git Bash / MSYS2:"
            echo "  eval \$(minikube docker-env)"
            echo ""
            echo "  # For PowerShell:"
            echo "  & minikube docker-env --shell powershell | Invoke-Expression"
            echo ""
            echo "  # For CMD:"
            echo "  @FOR /f \"tokens=*\" %i IN ('minikube docker-env --shell cmd') DO @%i"
            ;;
    esac
    echo ""
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "========================================"
    echo "  Minikube Docker Environment Setup"
    echo "========================================"
    echo ""

    start_minikube
    configure_docker_env
    verify_docker
    export_env_vars

    info "Setup complete! You can now build images for Minikube."
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
