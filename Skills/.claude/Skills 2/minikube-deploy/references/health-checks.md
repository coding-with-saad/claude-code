# Health Check Configuration Patterns

## Three-Probe Strategy

Kubernetes provides three distinct health probe types. Use all three to properly distinguish startup delays, traffic readiness, and ongoing availability.

### Probe Purposes

| Probe Type | Purpose | Controls | Timing |
|-----------|---------|----------|--------|
| **Startup** | Detect startup completion | Delays readiness/liveness checks | Generous (60s) |
| **Readiness** | Control traffic routing | Service endpoint membership | Quick (30s) |
| **Liveness** | Detect deadlocks/crashes | Pod restart trigger | Conservative (30s after startup) |

### Probe Execution Order

1. **Startup probe runs first**: Disables readiness and liveness until successful
2. **Readiness probe activates**: Controls whether pod receives traffic
3. **Liveness probe monitors**: Restarts pod if it becomes unresponsive

## Configuration Template

### HTTP GET Probes (Recommended)

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        ports:
        - containerPort: 8000

        # Startup Probe: 60s startup window
        startupProbe:
          httpGet:
            path: /health
            port: 8000
            scheme: HTTP
          initialDelaySeconds: 10  # Wait 10s before first check
          periodSeconds: 5         # Check every 5s
          timeoutSeconds: 3        # Fail if no response in 3s
          successThreshold: 1      # Consider started after 1 success
          failureThreshold: 12     # Allow 12 failures (60s) before restart

        # Readiness Probe: 30s detection window
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
            scheme: HTTP
          initialDelaySeconds: 5   # Start checking after startup
          periodSeconds: 10        # Check every 10s
          timeoutSeconds: 5        # Fail if no response in 5s
          successThreshold: 1      # Ready after 1 success
          failureThreshold: 3      # Mark unready after 3 failures (30s)

        # Liveness Probe: 30s detection window
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
            scheme: HTTP
          initialDelaySeconds: 30  # Give startup time before checking
          periodSeconds: 10        # Check every 10s
          timeoutSeconds: 5        # Fail if no response in 5s
          successThreshold: 1      # Healthy after 1 success
          failureThreshold: 3      # Restart after 3 failures (30s)
```

## Timing Configuration Guidelines

### Startup Probe

**Goal**: Allow sufficient time for application initialization without triggering liveness failure

**Configuration**:
- `initialDelaySeconds: 10` - Wait for container basics (file system, network)
- `periodSeconds: 5` - Frequent checks during startup
- `failureThreshold: 12` - Allows 60s total (12 × 5s = 60s)
- **Total window**: 10s delay + 60s checking = 70s maximum startup time

**Adjust for**:
- **Fast services** (Go, Rust): Reduce to failureThreshold: 6 (30s window)
- **Slow services** (large Next.js, ML models): Increase to failureThreshold: 18 (90s window)
- **Database-heavy startup**: Increase initialDelaySeconds: 15

### Readiness Probe

**Goal**: Quick detection of unhealthy state to stop routing traffic

**Configuration**:
- `initialDelaySeconds: 5` - Start checking soon after startup probe passes
- `periodSeconds: 10` - Balanced check frequency
- `failureThreshold: 3` - 30s to mark unready (3 × 10s = 30s)

**Adjust for**:
- **Critical services**: Reduce periodSeconds: 5 for faster detection
- **Dependent services**: Health endpoint should check upstream dependencies
- **Stateless services**: Can use aggressive timings (failureThreshold: 2)

### Liveness Probe

**Goal**: Conservative detection of deadlock/crash without false positives

**Configuration**:
- `initialDelaySeconds: 30` - Wait for normal operation before checking
- `periodSeconds: 10` - Regular monitoring
- `failureThreshold: 3` - 30s before restart (3 × 10s = 30s)

**Adjust for**:
- **Batch processing**: Increase failureThreshold: 6 (60s) for long operations
- **Stable services**: Can use conservative failureThreshold: 5 (50s)
- **Quick recovery**: Reduce to failureThreshold: 2 for faster restart

## Failure Scenarios

### Startup Failure

**Symptoms**: Pod never becomes ready, restarts repeatedly

**Kubernetes Action**: Restart pod (CrashLoopBackOff after multiple failures)

**Common Causes**:
- Missing environment variables or secrets
- Database connection failure
- Dependency service unavailable
- Slow initialization (exceeds 60s window)

**Debugging**:
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```

### Readiness Failure

**Symptoms**: Pod running but not receiving traffic

**Kubernetes Action**: Remove from Service endpoints (no traffic routed)

**Common Causes**:
- Temporary dependency outage (database, upstream API)
- Resource exhaustion (memory, CPU)
- Health endpoint error

**Debugging**:
```bash
kubectl get endpoints -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
# Check events for "Readiness probe failed"
```

### Liveness Failure

**Symptoms**: Pod restarts periodically

**Kubernetes Action**: Restart pod to recover from deadlock

**Common Causes**:
- Application deadlock or hung thread
- Memory leak causing slow response
- Infinite loop or blocking operation
- Health endpoint timeout

**Debugging**:
```bash
kubectl logs <pod-name> -n <namespace> --previous
# Check logs before restart for deadlock indicators
```

## Probe Type Comparison

### HTTP GET (Recommended)

```yaml
httpGet:
  path: /health
  port: 8000
  scheme: HTTP
```

**Advantages**:
- Verifies application logic (not just port open)
- Health endpoint can check dependencies
- Returns detailed status information
- Easy to debug (test with curl)
- No additional tools needed in container

**Use when**: Application exposes HTTP endpoint

### TCP Socket

```yaml
tcpSocket:
  port: 8000
```

**Advantages**:
- Simple, no HTTP server needed
- Works for non-HTTP services (databases, message queues)

**Disadvantages**:
- Only checks port open (not actual health)
- Cannot verify application logic
- Less informative for debugging

**Use when**: Non-HTTP service without health endpoint

### Exec Command

```yaml
exec:
  command:
  - cat
  - /tmp/healthy
```

**Advantages**:
- Maximum flexibility (any check possible)
- Works without network

**Disadvantages**:
- Requires tools in container image
- Higher resource overhead (shell process)
- More complex to debug
- Less portable

**Use when**: Custom health check logic required, no HTTP available

## Health Endpoint Implementation

### Basic Health Endpoint

**FastAPI (Python)**:
```python
from fastapi import FastAPI, Response

app = FastAPI()

@app.get("/health")
async def health_check():
    # Basic health check
    return {"status": "healthy"}
```

**Next.js (TypeScript)**:
```typescript
// pages/api/health.ts
import type { NextApiRequest, NextApiResponse } from 'next'

export default function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  res.status(200).json({ status: 'healthy' })
}
```

### Health Endpoint with Dependencies

**Check database connection**:
```python
from fastapi import FastAPI, Response
import asyncpg

app = FastAPI()

@app.get("/health")
async def health_check():
    try:
        # Check database connection
        conn = await asyncpg.connect(DATABASE_URL)
        await conn.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return Response(
            content={"status": "unhealthy", "error": str(e)},
            status_code=503
        )
```

**Response codes**:
- `200 OK`: Service healthy
- `503 Service Unavailable`: Service unhealthy (triggers probe failure)

## Helm Values Configuration

Define health check configuration in values.yaml:

```yaml
service1:
  healthCheck:
    enabled: true
    startupProbe:
      path: /health
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 12
    readinessProbe:
      path: /health
      initialDelaySeconds: 5
      periodSeconds: 10
      failureThreshold: 3
    livenessProbe:
      path: /health
      initialDelaySeconds: 30
      periodSeconds: 10
      failureThreshold: 3
```

Use in Deployment template:

```yaml
{{- if .Values.service1.healthCheck.enabled }}
startupProbe:
  httpGet:
    path: {{ .Values.service1.healthCheck.startupProbe.path }}
    port: {{ .Values.service1.service.port }}
  initialDelaySeconds: {{ .Values.service1.healthCheck.startupProbe.initialDelaySeconds }}
  periodSeconds: {{ .Values.service1.healthCheck.startupProbe.periodSeconds }}
  failureThreshold: {{ .Values.service1.healthCheck.startupProbe.failureThreshold }}
{{- end }}
```

## Best Practices

### DO

- ✅ Use HTTP GET probes for HTTP services
- ✅ Implement dedicated health endpoints
- ✅ Check critical dependencies in health endpoint
- ✅ Set initialDelaySeconds > 0 to avoid premature checks
- ✅ Liveness initialDelaySeconds > readiness initialDelaySeconds
- ✅ Make health endpoints lightweight (< 100ms response)
- ✅ Use failureThreshold to avoid false positives
- ✅ Return 503 status code when unhealthy

### DON'T

- ❌ Use only readiness probe (missing startup/liveness)
- ❌ Set tight timeouts that cause false restarts
- ❌ Check slow dependencies in liveness probe
- ❌ Use exec probes for HTTP services
- ❌ Ignore probe failures in logs
- ❌ Set liveness before readiness (causes restart loops)
- ❌ Make health endpoints heavyweight (> 500ms)

## Common Patterns by Service Type

### Web Application (Next.js, React)

```yaml
startupProbe:
  httpGet: {path: /api/health, port: 3000}
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 12  # 60s for build/hydration

readinessProbe:
  httpGet: {path: /api/health, port: 3000}
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3

livenessProbe:
  httpGet: {path: /api/health, port: 3000}
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
```

### API Service (FastAPI, Express)

```yaml
startupProbe:
  httpGet: {path: /health, port: 8000}
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 12

readinessProbe:
  httpGet: {path: /health, port: 8000}
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3

livenessProbe:
  httpGet: {path: /health, port: 8000}
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
```

### Background Worker (Celery, Bull)

```yaml
# No readiness probe (doesn't receive HTTP traffic)
livenessProbe:
  exec:
    command: ["/bin/sh", "-c", "celery -A app inspect ping"]
  initialDelaySeconds: 30
  periodSeconds: 30
  failureThreshold: 3
```

## Troubleshooting

### Pods restarting frequently

**Check liveness probe**:
```bash
kubectl describe pod <pod> -n <ns> | grep -A 10 "Liveness"
```

**Solutions**:
- Increase `failureThreshold` or `periodSeconds`
- Increase `timeoutSeconds` if health endpoint is slow
- Check health endpoint for errors

### Pods not receiving traffic

**Check readiness probe**:
```bash
kubectl get endpoints -n <ns>
kubectl describe pod <pod> -n <ns> | grep -A 10 "Readiness"
```

**Solutions**:
- Verify health endpoint returns 200
- Check health endpoint dependencies (database, APIs)
- Increase `failureThreshold` if startup is slow

### Pods stuck in CrashLoopBackOff

**Check startup probe**:
```bash
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
```

**Solutions**:
- Increase `failureThreshold` for longer startup
- Fix application startup errors
- Check environment variables and secrets
