# Docker/Kubernetes Deployment

## Table of Contents
- [Environment Configuration](#environment-configuration)
- [Docker Setup](#docker-setup)
- [Docker Compose](#docker-compose)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Health Checks](#health-checks)

## Environment Configuration

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/dbname

# OpenAI
OPENAI_API_KEY=sk-...

# MCP Server URL
# Local: http://localhost:8001/mcp
# Docker Compose: http://mcp-server:8001/mcp
# Kubernetes: http://mcp-server.namespace.svc.cluster.local:8001/mcp
MCP_SERVER_URL=http://localhost:8001/mcp

# CORS
CORS_ORIGINS=["http://localhost:3000"]

# Logging
LOG_LEVEL=info
```

### URL Patterns by Environment

| Environment | MCP_SERVER_URL |
|-------------|----------------|
| Local Dev | `http://localhost:8001/mcp` |
| Docker Compose | `http://mcp-server:8001/mcp` |
| Kubernetes | `http://mcp-server.default.svc.cluster.local:8001/mcp` |

**Important**: No trailing slash in the URL.

## Docker Setup

### MCP Server Dockerfile

```dockerfile
# Dockerfile.mcp
FROM python:3.13-slim

WORKDIR /app

# Install uv
RUN pip install uv

# Copy project files
COPY pyproject.toml uv.lock ./
COPY src/ ./src/

# Install dependencies
RUN uv sync --frozen

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Run MCP server
CMD ["uv", "run", "uvicorn", "src.mcp.main:app", "--host", "0.0.0.0", "--port", "8001"]
```

### Main API Dockerfile

```dockerfile
# Dockerfile.api
FROM python:3.13-slim

WORKDIR /app

RUN pip install uv

COPY pyproject.toml uv.lock ./
COPY src/ ./src/
COPY main.py ./

RUN uv sync --frozen

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Docker Compose

### Complete docker-compose.yml

```yaml
version: '3.8'

services:
  # MCP Server
  mcp-server:
    build:
      context: .
      dockerfile: Dockerfile.mcp
    ports:
      - "8001:8001"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - LOG_LEVEL=info
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    networks:
      - app-network

  # Main API with ChatKit
  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - MCP_SERVER_URL=http://mcp-server:8001/mcp
      - CORS_ORIGINS=["http://localhost:3000"]
      - LOG_LEVEL=info
    depends_on:
      mcp-server:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network

  # Frontend (optional)
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - api
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

### Running with Docker Compose

```bash
# Build and start
docker-compose up --build

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f api mcp-server

# Stop
docker-compose down
```

## Kubernetes Deployment

### MCP Server Deployment

```yaml
# k8s/mcp-server.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-server
  labels:
    app: mcp-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mcp-server
  template:
    metadata:
      labels:
        app: mcp-server
    spec:
      containers:
        - name: mcp-server
          image: your-registry/mcp-server:latest
          ports:
            - containerPort: 8001
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url
            - name: LOG_LEVEL
              value: "info"
          livenessProbe:
            httpGet:
              path: /health
              port: 8001
            initialDelaySeconds: 10
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /health
              port: 8001
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: mcp-server
spec:
  selector:
    app: mcp-server
  ports:
    - port: 8001
      targetPort: 8001
  type: ClusterIP
```

### Main API Deployment

```yaml
# k8s/api.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: your-registry/api:latest
          ports:
            - containerPort: 8000
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url
            - name: OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: openai-api-key
            - name: MCP_SERVER_URL
              value: "http://mcp-server.default.svc.cluster.local:8001/mcp"
            - name: LOG_LEVEL
              value: "info"
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 15
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 10
            periodSeconds: 10
          resources:
            requests:
              memory: "512Mi"
              cpu: "200m"
            limits:
              memory: "1Gi"
              cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
    - port: 8000
      targetPort: 8000
  type: ClusterIP
```

### Secrets

```yaml
# k8s/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  database-url: "postgresql+asyncpg://user:password@db-host:5432/dbname"
  openai-api-key: "sk-..."
```

### ConfigMap

```yaml
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  CORS_ORIGINS: '["https://your-domain.com"]'
```

### Ingress

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  rules:
    - host: api.your-domain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 8000
```

### Deploying to Kubernetes

```bash
# Apply secrets first
kubectl apply -f k8s/secrets.yaml

# Apply configmap
kubectl apply -f k8s/configmap.yaml

# Deploy MCP server
kubectl apply -f k8s/mcp-server.yaml

# Wait for MCP server to be ready
kubectl wait --for=condition=available deployment/mcp-server --timeout=120s

# Deploy API
kubectl apply -f k8s/api.yaml

# Apply ingress
kubectl apply -f k8s/ingress.yaml

# Check status
kubectl get pods
kubectl get services
```

## Health Checks

### MCP Server Health Endpoint

```python
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "mcp-server"}
```

### API Health Endpoint

```python
@app.get("/health")
async def health_check():
    # Optionally check MCP connection
    try:
        dispatcher = get_dispatcher()
        if dispatcher._is_initialized:
            return {"status": "healthy", "mcp": "connected"}
        return {"status": "healthy", "mcp": "not_initialized"}
    except Exception as e:
        return {"status": "degraded", "error": str(e)}
```

### Kubernetes Probe Configuration

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 15  # Wait for startup
  periodSeconds: 30        # Check every 30s
  timeoutSeconds: 10       # Timeout after 10s
  failureThreshold: 3      # Restart after 3 failures

readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10  # Wait before first check
  periodSeconds: 10        # Check every 10s
  successThreshold: 1      # Ready after 1 success
  failureThreshold: 3      # Not ready after 3 failures
```
