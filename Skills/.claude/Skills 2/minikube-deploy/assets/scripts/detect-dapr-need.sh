#!/bin/bash
# =============================================================================
# Dapr Requirement Detector
# Analyzes project to determine if Dapr is needed/beneficial
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
hint() { echo -e "${BLUE}[HINT]${NC} $1"; }
result() { echo -e "${CYAN}[RESULT]${NC} $1"; }

DAPR_SCORE=0
DAPR_REASONS=()

# =============================================================================
# Check Docker Compose for Dapr Indicators
# =============================================================================
check_docker_compose() {
    local compose_files=$(ls docker-compose*.yml docker-compose*.yaml compose*.yml 2>/dev/null || true)

    if [ -z "$compose_files" ]; then
        return
    fi

    info "Checking docker-compose files..."

    for file in $compose_files; do
        # Check for Redis
        if grep -qi "redis" "$file" 2>/dev/null; then
            DAPR_SCORE=$((DAPR_SCORE + 2))
            DAPR_REASONS+=("Redis found in $file (pub/sub, state store)")
        fi

        # Check for Kafka/Redpanda
        if grep -qiE "(kafka|redpanda)" "$file" 2>/dev/null; then
            DAPR_SCORE=$((DAPR_SCORE + 3))
            DAPR_REASONS+=("Kafka/Redpanda found in $file (event streaming)")
        fi

        # Check for RabbitMQ
        if grep -qi "rabbitmq" "$file" 2>/dev/null; then
            DAPR_SCORE=$((DAPR_SCORE + 2))
            DAPR_REASONS+=("RabbitMQ found in $file (message queue)")
        fi

        # Check for NATS
        if grep -qi "nats" "$file" 2>/dev/null; then
            DAPR_SCORE=$((DAPR_SCORE + 2))
            DAPR_REASONS+=("NATS found in $file (messaging)")
        fi
    done
}

# =============================================================================
# Check Code for Pub/Sub Patterns
# =============================================================================
check_pubsub_patterns() {
    info "Checking for pub/sub patterns in code..."

    # Python Dapr SDK
    if grep -r "DaprClient" . --include="*.py" 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 5))
        DAPR_REASONS+=("Dapr SDK already used in Python code")
    fi

    # Python pub/sub patterns
    if grep -rE "(publish_event|subscribe|pubsub)" . --include="*.py" 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 2))
        DAPR_REASONS+=("Pub/sub patterns found in Python code")
    fi

    # Node.js/TypeScript event patterns
    if grep -rE "(EventEmitter|emit\(|on\(.*event)" . --include="*.ts" --include="*.js" 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 1))
        DAPR_REASONS+=("Event patterns found in TypeScript/JavaScript")
    fi

    # Kafka client usage
    if grep -rE "(kafkajs|node-rdkafka|confluent-kafka)" . --include="*.ts" --include="*.js" --include="*.py" --include="package.json" --include="requirements.txt" 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 3))
        DAPR_REASONS+=("Kafka client library detected")
    fi
}

# =============================================================================
# Check for Cron/Scheduled Job Patterns
# =============================================================================
check_cron_patterns() {
    info "Checking for scheduled job patterns..."

    # Python schedulers
    if grep -rE "(schedule|APScheduler|celery|cron)" . --include="*.py" 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 2))
        DAPR_REASONS+=("Scheduler patterns found (Dapr cron bindings can replace)")
    fi

    # Node cron
    if grep -rE "(node-cron|cron|setInterval.*[0-9]+000)" . --include="*.ts" --include="*.js" 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 1))
        DAPR_REASONS+=("Cron/interval patterns found in Node.js")
    fi
}

# =============================================================================
# Check for State Management Patterns
# =============================================================================
check_state_patterns() {
    info "Checking for state management patterns..."

    # Redis client usage for state
    if grep -rE "(ioredis|redis-py|redis\.Redis)" . --include="*.py" --include="*.ts" --include="*.js" 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 2))
        DAPR_REASONS+=("Redis client for state (Dapr state store can abstract)")
    fi
}

# =============================================================================
# Check for Multiple Services
# =============================================================================
check_microservices() {
    info "Checking for microservices architecture..."

    # Count Dockerfiles
    local dockerfile_count=$(find . -name "Dockerfile" 2>/dev/null | grep -v node_modules | grep -v .git | wc -l)

    if [ "$dockerfile_count" -gt 2 ]; then
        DAPR_SCORE=$((DAPR_SCORE + 2))
        DAPR_REASONS+=("$dockerfile_count services detected (Dapr helps with service-to-service calls)")
    fi
}

# =============================================================================
# Check Existing Dapr Configuration
# =============================================================================
check_existing_dapr() {
    info "Checking for existing Dapr configuration..."

    # Check for dapr components
    if find . -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs grep -l "dapr.io" 2>/dev/null | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 10))
        DAPR_REASONS+=("Existing Dapr components found - Dapr definitely needed!")
    fi

    # Check helm values for dapr
    if grep -r "dapr:" helm/ --include="*.yaml" 2>/dev/null | head -1 | grep -q .; then
        DAPR_SCORE=$((DAPR_SCORE + 10))
        DAPR_REASONS+=("Dapr configuration in Helm values")
    fi
}

# =============================================================================
# Generate Recommendation
# =============================================================================
generate_recommendation() {
    echo ""
    echo "========================================"
    echo "  Dapr Requirement Analysis"
    echo "========================================"
    echo ""

    if [ ${#DAPR_REASONS[@]} -gt 0 ]; then
        info "Detected indicators:"
        for reason in "${DAPR_REASONS[@]}"; do
            echo "  - $reason"
        done
        echo ""
    fi

    echo "Dapr Score: $DAPR_SCORE"
    echo ""

    if [ $DAPR_SCORE -ge 5 ]; then
        result "RECOMMENDATION: ENABLE DAPR"
        echo ""
        echo "Dapr is strongly recommended for this project."
        echo ""
        echo "Add to values.yaml:"
        echo "  dapr:"
        echo "    enabled: true"
        echo ""
        echo "DAPR_NEEDED=true"
    elif [ $DAPR_SCORE -ge 2 ]; then
        result "RECOMMENDATION: OPTIONAL - ASK USER"
        echo ""
        echo "Dapr could benefit this project but is not required."
        echo "Ask user: 'Would you like to enable Dapr for event-driven features?'"
        echo ""
        echo "DAPR_NEEDED=optional"
    else
        result "RECOMMENDATION: NO DAPR NEEDED"
        echo ""
        echo "This project doesn't show patterns that require Dapr."
        echo "Deploy without Dapr to keep things simple."
        echo ""
        echo "DAPR_NEEDED=false"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "========================================"
    echo "  Dapr Requirement Detector"
    echo "========================================"
    echo ""

    check_existing_dapr
    check_docker_compose
    check_pubsub_patterns
    check_cron_patterns
    check_state_patterns
    check_microservices

    generate_recommendation
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
