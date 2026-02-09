#!/bin/bash
# =============================================================================
# Health Probe Endpoint Detector
# Scans codebase to find health check endpoints for Kubernetes probes
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
hint() { echo -e "${BLUE}[HINT]${NC} $1"; }

# Default health paths by framework
declare -A FRAMEWORK_DEFAULTS=(
    ["fastapi"]="/health"
    ["flask"]="/health"
    ["express"]="/health"
    ["nestjs"]="/health"
    ["nextjs"]="/api/health"
    ["django"]="/health/"
    ["spring"]="/actuator/health"
    ["gin"]="/health"
    ["echo"]="/health"
)

# =============================================================================
# Detect Framework
# =============================================================================
detect_framework() {
    local dir="$1"

    # Python frameworks
    if [ -f "$dir/requirements.txt" ] || [ -f "$dir/pyproject.toml" ]; then
        if grep -q "fastapi" "$dir/requirements.txt" "$dir/pyproject.toml" 2>/dev/null; then
            echo "fastapi"
            return
        elif grep -q "flask" "$dir/requirements.txt" "$dir/pyproject.toml" 2>/dev/null; then
            echo "flask"
            return
        elif grep -q "django" "$dir/requirements.txt" "$dir/pyproject.toml" 2>/dev/null; then
            echo "django"
            return
        fi
    fi

    # Node.js frameworks
    if [ -f "$dir/package.json" ]; then
        if grep -q '"next"' "$dir/package.json" 2>/dev/null; then
            echo "nextjs"
            return
        elif grep -q '"@nestjs' "$dir/package.json" 2>/dev/null; then
            echo "nestjs"
            return
        elif grep -q '"express"' "$dir/package.json" 2>/dev/null; then
            echo "express"
            return
        fi
    fi

    # Go frameworks
    if [ -f "$dir/go.mod" ]; then
        if grep -q "gin-gonic" "$dir/go.mod" 2>/dev/null; then
            echo "gin"
            return
        elif grep -q "labstack/echo" "$dir/go.mod" 2>/dev/null; then
            echo "echo"
            return
        fi
    fi

    # Java/Spring
    if [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ]; then
        if grep -q "spring-boot" "$dir/pom.xml" "$dir/build.gradle" 2>/dev/null; then
            echo "spring"
            return
        fi
    fi

    echo "unknown"
}

# =============================================================================
# Search for Health Endpoints in Code
# =============================================================================
find_health_endpoints() {
    local dir="$1"
    local found_paths=()

    # Common health endpoint patterns
    local patterns=(
        '/health'
        '/api/health'
        '/healthz'
        '/ready'
        '/readiness'
        '/liveness'
        '/ping'
        '/status'
        '/_health'
        '/api/v1/health'
    )

    # Search in code files
    for pattern in "${patterns[@]}"; do
        # Python
        if grep -r "\"$pattern\"" "$dir" --include="*.py" 2>/dev/null | head -1 | grep -q .; then
            found_paths+=("$pattern")
        fi
        # JavaScript/TypeScript
        if grep -r "'$pattern'" "$dir" --include="*.ts" --include="*.js" --include="*.tsx" 2>/dev/null | head -1 | grep -q .; then
            found_paths+=("$pattern")
        fi
        # Go
        if grep -r "\"$pattern\"" "$dir" --include="*.go" 2>/dev/null | head -1 | grep -q .; then
            found_paths+=("$pattern")
        fi
    done

    # Remove duplicates and print
    printf '%s\n' "${found_paths[@]}" | sort -u
}

# =============================================================================
# Analyze Service Directory
# =============================================================================
analyze_service() {
    local dir="$1"
    local service_name=$(basename "$dir")

    echo ""
    echo "Service: $service_name ($dir)"
    echo "----------------------------------------"

    # Detect framework
    local framework=$(detect_framework "$dir")
    info "Framework: $framework"

    # Search for health endpoints in code
    local endpoints=$(find_health_endpoints "$dir")

    if [ -n "$endpoints" ]; then
        info "Found health endpoints in code:"
        echo "$endpoints" | while read -r ep; do
            echo "  - $ep"
        done
        # Return first found endpoint
        echo "$endpoints" | head -1
    elif [ "$framework" != "unknown" ]; then
        local default_path="${FRAMEWORK_DEFAULTS[$framework]}"
        hint "No explicit health endpoint found. Framework default: $default_path"
        echo "$default_path"
    else
        warn "No health endpoint detected. Defaulting to: /"
        echo "/"
    fi
}

# =============================================================================
# Main - Scan All Services
# =============================================================================
main() {
    echo "========================================"
    echo "  Health Probe Endpoint Detector"
    echo "========================================"

    # Find all Dockerfiles and analyze their directories
    find . -name "Dockerfile" 2>/dev/null | grep -v node_modules | grep -v ".git" | while read -r dockerfile; do
        dir=$(dirname "$dockerfile")
        analyze_service "$dir"
    done

    echo ""
    echo "========================================"
    echo "  Probe Configuration Recommendations"
    echo "========================================"
    echo ""
    echo "For each service, add to values.yaml:"
    echo ""
    echo "  probes:"
    echo "    enabled: true"
    echo "    path: <detected-path>"
    echo "    initialDelaySeconds: 10"
    echo "    periodSeconds: 10"
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
