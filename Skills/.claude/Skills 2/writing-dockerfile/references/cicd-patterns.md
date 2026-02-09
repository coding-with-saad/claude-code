# CI/CD & Deployment Patterns

GitHub Actions workflows, Kubernetes integration, and production deployment patterns.

## Table of Contents

- [GitHub Actions Workflows](#github-actions-workflows)
- [Kubernetes Integration](#kubernetes-integration)
- [Docker Compose Integration](#docker-compose-integration)
- [.dockerignore Patterns](#dockerignore-patterns)
- [Production Checklist](#production-checklist)

---

## GitHub Actions Workflows

### Basic Build and Push

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: user/app:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Multi-Platform Build

```yaml
name: Multi-Platform Build

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: user/app
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            VERSION=${{ steps.meta.outputs.version }}
```

### With Build Secrets

```yaml
- name: Build and push
  uses: docker/build-push-action@v6
  with:
    context: .
    push: true
    tags: user/app:latest
    secrets: |
      "npm_token=${{ secrets.NPM_TOKEN }}"
      "ssh_key=${{ secrets.SSH_PRIVATE_KEY }}"
    ssh: |
      default=${{ env.SSH_AUTH_SOCK }}
```

---

## Kubernetes Integration

### Readiness/Liveness Probes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      containers:
      - name: app
        image: app:latest
        ports:
        - containerPort: 3000
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 30
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          failureThreshold: 30
          periodSeconds: 10
```

### Resource Limits

```yaml
containers:
- name: app
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "500m"
```

### Security Context

```yaml
containers:
- name: app
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    runAsGroup: 1001
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
```

---

## Docker Compose Integration

### Development Setup

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      args:
        - DATABASE_URL=dummy  # Build-time only
        - NEXT_PUBLIC_API_URL=http://api:8000
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/db
      - NODE_ENV=production
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:3000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=db
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d db"]
      interval: 5s
      timeout: 5s
      retries: 5
```

### Production Setup

```yaml
version: '3.8'

services:
  app:
    image: registry.example.com/app:${VERSION:-latest}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    environment:
      - DATABASE_URL  # Injected from host
      - SECRET_KEY
    read_only: true
    tmpfs:
      - /tmp
      - /app/logs
```

---

## .dockerignore Patterns

Reduce build context and protect secrets:

```gitignore
# Version control
.git
.gitignore
.gitattributes

# Dependencies (rebuilt in container)
node_modules
__pycache__
*.pyc
.venv
venv
target/

# Build outputs
dist
build
.next
*.egg-info

# IDE/Editor
.vscode
.idea
*.swp
*.swo
.DS_Store

# Testing
.pytest_cache
coverage
*.test
__tests__
*.spec.js
*.test.js

# Documentation (not needed in image)
*.md
docs/
README*
CHANGELOG*
LICENSE

# CI/CD configs
.github
.gitlab-ci.yml
Jenkinsfile
.circleci

# Secrets (CRITICAL)
.env
.env.*
*.key
*.pem
*.cert
secrets/
credentials.json

# Docker files (avoid recursion)
Dockerfile*
docker-compose*
.dockerignore

# Misc
*.log
tmp/
temp/
```

---

## Production Checklist

### Essential

- [ ] Use `# syntax=docker/dockerfile:1` directive
- [ ] Multi-stage build (deps → builder → runtime)
- [ ] Pinned base image versions (no `latest`)
- [ ] Non-root user with specific UID/GID
- [ ] Health checks with native tools
- [ ] Exec form CMD/ENTRYPOINT
- [ ] Build-time secrets cleared before runtime
- [ ] Minimal runtime image
- [ ] .dockerignore file
- [ ] LABEL metadata for tracking

### Performance

- [ ] BuildKit cache mounts for package managers
- [ ] Order COPY by change frequency
- [ ] Multi-platform builds (amd64/arm64)
- [ ] Parallel stage execution
- [ ] Zstd compression

### Security

- [ ] No secrets in layers
- [ ] Read-only root filesystem compatible
- [ ] Secret mounts for build-time credentials
- [ ] Vulnerability scanning (Docker Scout)
- [ ] Regular base image updates

### Cloud-Native

- [ ] Kubernetes-compatible health probes
- [ ] Graceful shutdown handling
- [ ] 12-factor app compliance
- [ ] Structured JSON logging
- [ ] Resource limits awareness
- [ ] Init process for signal handling
