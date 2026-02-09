# Dapr Integration Guide

## Overview

Dapr (Distributed Application Runtime) provides building blocks for microservices: pub/sub, state management, service invocation, and bindings. This guide covers integrating Dapr with Minikube deployments.

## Quick Decision: Do You Need Dapr?

| Use Case | Dapr Needed? |
|----------|--------------|
| Simple REST APIs | No |
| Event-driven architecture | Yes |
| Pub/Sub messaging | Yes |
| Distributed state management | Yes |
| Scheduled jobs (cron) | Yes |
| Service-to-service calls with retries | Yes |

## Installation

### Dapr Control Plane (One-time Setup)

```bash
# Add Dapr Helm repo
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

# Install Dapr
helm install dapr dapr/dapr \
  --namespace dapr-system \
  --create-namespace \
  --wait
```

### Verify Installation

```bash
kubectl get pods -n dapr-system
# Expected: dapr-operator, dapr-sentry, dapr-sidecar-injector, dapr-placement
```

## Dapr Components

### 1. Pub/Sub Component

**Redis (Local Development):**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: {{APP_NAME}}-pubsub
  namespace: {{NAMESPACE}}
spec:
  type: pubsub.redis
  version: v1
  metadata:
    - name: redisHost
      value: "redis-master.{{NAMESPACE}}.svc.cluster.local:6379"
    - name: redisPassword
      value: ""
    - name: enableTLS
      value: "false"
```

**Kafka (Production):**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: {{APP_NAME}}-pubsub
  namespace: {{NAMESPACE}}
spec:
  type: pubsub.kafka
  version: v1
  metadata:
    - name: brokers
      value: "kafka.data.svc.cluster.local:9092"
    - name: consumerGroup
      value: "{{APP_NAME}}-group"
    - name: authType
      value: "none"
```

### 2. State Store Component

**Redis State:**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: {{APP_NAME}}-statestore
  namespace: {{NAMESPACE}}
spec:
  type: state.redis
  version: v1
  metadata:
    - name: redisHost
      value: "redis-master.{{NAMESPACE}}.svc.cluster.local:6379"
    - name: redisPassword
      value: ""
    - name: actorStateStore
      value: "false"
```

**PostgreSQL State:**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: {{APP_NAME}}-statestore
  namespace: {{NAMESPACE}}
spec:
  type: state.postgresql
  version: v1
  metadata:
    - name: connectionString
      secretKeyRef:
        name: {{APP_NAME}}-secrets
        key: DATABASE_URL
    - name: tableName
      value: "dapr_state"
    - name: cleanupIntervalInSeconds
      value: "3600"
```

### 3. Cron Binding Component

```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: {{BINDING_NAME}}-cron
  namespace: {{NAMESPACE}}
spec:
  type: bindings.cron
  version: v1
  metadata:
    - name: schedule
      value: "*/5 * * * *"  # Every 5 minutes
    - name: direction
      value: "input"
```

## Enabling Dapr Sidecar

Add annotations to Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{SERVICE_NAME}}
spec:
  template:
    metadata:
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "{{APP_NAME}}-{{SERVICE_NAME}}"
        dapr.io/app-port: "{{APP_PORT}}"
        dapr.io/log-level: "info"
        dapr.io/enable-api-logging: "true"
```

### Helm Template with Dapr Toggle

```yaml
{{- if .Values.dapr.enabled }}
annotations:
  dapr.io/enabled: "true"
  dapr.io/app-id: {{ include "myapp.fullname" . }}-{{ .Values.serviceName }}
  dapr.io/app-port: {{ .Values.service.port | quote }}
  dapr.io/log-level: {{ .Values.dapr.logLevel | default "info" | quote }}
{{- end }}
```

## Values.yaml Structure for Dapr

```yaml
# Dapr configuration
dapr:
  enabled: true
  logLevel: "info"

  # Pub/Sub configuration
  pubsub:
    type: "pubsub.redis"
    metadata:
      redisHost: "redis-master:6379"
      redisPassword: ""
      enableTLS: "false"

  # State store configuration
  statestore:
    type: "state.redis"
    redisHost: "redis-master:6379"
    redisPassword: ""

  # Cron bindings
  cronBindings:
    reminder:
      schedule: "*/5 * * * *"
    cleanup:
      schedule: "0 * * * *"

# Redis dependency (when using Redis for Dapr)
redis:
  enabled: true
```

## Application Code Integration

### Python (FastAPI) Pub/Sub

```python
from dapr.clients import DaprClient

# Publish event
async def publish_event(topic: str, data: dict):
    with DaprClient() as client:
        client.publish_event(
            pubsub_name="myapp-pubsub",
            topic_name=topic,
            data=json.dumps(data)
        )

# Subscribe endpoint
@app.post("/dapr/subscribe")
async def subscribe():
    return [
        {"pubsubname": "myapp-pubsub", "topic": "orders", "route": "/orders"}
    ]

@app.post("/orders")
async def handle_order(event: dict):
    # Process event
    pass
```

### Cron Binding Handler

```python
@app.post("/bindings/{binding_name}")
async def handle_binding(binding_name: str):
    if binding_name == "reminder-cron":
        await process_reminders()
    return {"status": "ok"}
```

## Debugging Dapr

### Check Sidecar Injection

```bash
# Pod should show 2/2 containers (app + daprd)
kubectl get pods -n {{NAMESPACE}}

# Check annotations
kubectl describe pod {{POD_NAME}} -n {{NAMESPACE}} | grep dapr
```

### View Dapr Logs

```bash
# Application Dapr sidecar
kubectl logs {{POD_NAME}} -n {{NAMESPACE}} -c daprd

# Dapr operator logs
kubectl logs -l app=dapr-operator -n dapr-system
```

### Test Pub/Sub

```bash
# Port-forward to Dapr sidecar
kubectl port-forward {{POD_NAME}} 3500:3500 -n {{NAMESPACE}}

# Publish test message
curl -X POST http://localhost:3500/v1.0/publish/{{APP_NAME}}-pubsub/test-topic \
  -H "Content-Type: application/json" \
  -d '{"message": "hello"}'
```

### Check Components

```bash
kubectl get components -n {{NAMESPACE}}
kubectl describe component {{COMPONENT_NAME}} -n {{NAMESPACE}}
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Sidecar not injecting | Missing annotations | Add `dapr.io/enabled: "true"` |
| Component not found | Wrong namespace | Deploy component to same namespace as app |
| Redis connection failed | Redis not installed | Install Redis: `helm install redis bitnami/redis` |
| Pub/sub not receiving | Wrong pubsub name | Verify component name matches code |

## Redis Installation for Local Dapr

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis \
  --namespace {{NAMESPACE}} \
  --set auth.enabled=false \
  --set architecture=standalone \
  --wait
```
