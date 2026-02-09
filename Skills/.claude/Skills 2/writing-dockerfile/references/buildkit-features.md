# BuildKit Features & Optimization

BuildKit cache mounts, modern syntax, and optimization patterns.

## Table of Contents

- [Package Manager Cache Mounts](#package-manager-cache-mounts)
- [BuildKit 1.20+ Features](#buildkit-120-features)
- [Multi-Stage Optimization](#multi-stage-optimization)
- [Environment Variable Patterns](#environment-variable-patterns)
- [Performance Tips](#performance-tips)

---

## Package Manager Cache Mounts

Cache dependencies across builds for faster rebuilds.

```dockerfile
# pnpm (Modern Node.js - Recommended)
RUN --mount=type=cache,id=pnpm,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile

# npm
RUN --mount=type=cache,id=npm,target=/root/.npm \
    npm ci --only=production

# yarn
RUN --mount=type=cache,id=yarn,target=/root/.yarn \
    yarn install --frozen-lockfile --production

# bun
RUN --mount=type=cache,id=bun,target=/root/.bun/install/cache \
    bun install --frozen-lockfile

# uv (Modern Python - Recommended)
RUN --mount=type=cache,id=uv,target=/root/.cache/uv \
    uv pip install --no-cache -r requirements.txt

# pdm
RUN --mount=type=cache,id=pdm,target=/root/.cache/pdm \
    pdm install --prod --no-editable

# poetry
RUN --mount=type=cache,target=/tmp/poetry_cache \
    poetry install --only=main --no-root

# pip (legacy)
RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

# cargo (Rust)
RUN --mount=type=cache,id=cargo,target=/usr/local/cargo/registry \
    cargo build --release

# maven (Java)
RUN --mount=type=cache,id=maven,target=/root/.m2 \
    mvn package -DskipTests

# gradle (Java/Kotlin)
RUN --mount=type=cache,id=gradle,target=/root/.gradle \
    ./gradlew installDist --no-daemon

# go modules
RUN --mount=type=cache,id=gomod,target=/go/pkg/mod \
    go mod download

# composer (PHP)
RUN --mount=type=cache,id=composer,target=/tmp/cache \
    composer install --no-dev --optimize-autoloader

# bundler (Ruby)
RUN --mount=type=cache,id=bundler,target=/root/.gem \
    bundle install --jobs 4 --retry 3

# dotnet (C#/.NET)
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet restore
```

---

## BuildKit 1.20+ Features

### --security Flag for RUN (GA in 1.20)

```dockerfile
# Run with no new privileges (use sparingly)
RUN --security=insecure apt-get update

# Default secure mode (recommended)
RUN --security=sandbox pip install -r requirements.txt
```

### --parents Flag for COPY (GA in 1.20)

Preserve directory structure when copying:

```dockerfile
# Copy preserving parent directories
COPY --parents src/components/**/*.tsx ./
# Results in: ./src/components/Button/Button.tsx

# Without --parents (flattened)
COPY src/components/**/*.tsx ./components/
# Results in: ./components/Button.tsx
```

### Heredoc Syntax (Stable)

Multiline scripts without escaping:

```dockerfile
# Multiline RUN
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates
rm -rf /var/lib/apt/lists/*
EOF

# Inline config files
COPY <<EOF /app/config.json
{
  "port": 3000,
  "environment": "production"
}
EOF

# With shell specification
RUN <<-PYTHON python3
import json
config = {"app": "myapp", "version": "1.0"}
print(json.dumps(config))
PYTHON
```

### Zstd Compression (Recommended)

Faster than gzip for both compression and decompression:

```bash
docker buildx build \
  --output type=image,compression=zstd,compression-level=3 \
  --tag myapp:latest .
```

### Parallel Stage Execution

BuildKit automatically parallelizes independent stages:

```dockerfile
# These run in parallel
FROM node:22-slim AS frontend-deps
COPY frontend/package.json ./
RUN npm ci

FROM python:3.13-slim AS backend-deps
COPY backend/requirements.txt ./
RUN pip install -r requirements.txt

# This waits for both
FROM node:22-slim AS final
COPY --from=frontend-deps /app/node_modules ./frontend/
COPY --from=backend-deps /usr/local/lib/python3.13 /usr/local/lib/python3.13
```

---

## Multi-Stage Optimization

### Dependency Copying Pattern

Copy manifests first for better layer caching:

```dockerfile
# Copy only dependency manifests
COPY package.json pnpm-lock.yaml ./
COPY pyproject.toml uv.lock ./
COPY go.mod go.sum ./

# Then copy source separately
COPY . .
```

### Artifact Selection Pattern

Copy only what's needed for runtime:

```dockerfile
# Node.js - standalone output only
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Python - virtual environment only
COPY --from=builder /opt/venv /opt/venv

# Go - single binary
COPY --from=builder /app/server /server

# Java - JAR only
COPY --from=builder /app/target/*.jar app.jar
```

### Bind Mounts for Builds

Build without copying source to image:

```dockerfile
FROM golang:1.22-slim AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
RUN --mount=type=bind,target=. \
    go build -o /app/server .
```

---

## Environment Variable Patterns

### Build-Time vs Runtime

```dockerfile
# Build-time (cleared after use)
ARG BUILD_ARG=value
ENV BUILD_VAR=$BUILD_ARG
RUN build-command
ENV BUILD_VAR=""

# Runtime-only (injected at deployment)
ENV RUNTIME_VAR  # Set in docker-compose/K8s
```

### Language-Specific Patterns

```dockerfile
# Node.js
ARG NODE_ENV=production
ARG NEXT_PUBLIC_API_URL
ARG DATABASE_URL=dummy
ENV NODE_ENV=$NODE_ENV
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV DATABASE_URL=$DATABASE_URL

# Python
ARG DJANGO_SETTINGS_MODULE
ARG SECRET_KEY=dummy
ENV DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
ENV SECRET_KEY=$SECRET_KEY

# Java
ARG SPRING_PROFILES_ACTIVE=prod
ARG JDBC_URL=dummy
ENV SPRING_PROFILES_ACTIVE=$SPRING_PROFILES_ACTIVE
ENV JDBC_URL=$JDBC_URL
```

---

## Performance Tips

### Layer Ordering

Order by change frequency (least → most):

1. Base image selection
2. System dependencies
3. Package manifests (lockfiles)
4. Dependency installation
5. Source code
6. Build command

### Cache Backends

```bash
# GitHub Actions cache
docker buildx build \
  --cache-from type=gha \
  --cache-to type=gha,mode=max .

# Registry cache
docker buildx build \
  --cache-from type=registry,ref=user/app:cache \
  --cache-to type=registry,ref=user/app:cache,mode=max .

# Local cache
docker buildx build \
  --cache-from type=local,src=/tmp/cache \
  --cache-to type=local,dest=/tmp/cache,mode=max .

# S3 cache
docker buildx build \
  --cache-from type=s3,region=us-east-1,bucket=my-cache \
  --cache-to type=s3,region=us-east-1,bucket=my-cache,mode=max .
```

### Essential Checklist

- [ ] Use `# syntax=docker/dockerfile:1` directive
- [ ] Leverage cache mounts for package managers
- [ ] Order layers by change frequency
- [ ] Use bind mounts for builds when appropriate
- [ ] Enable parallel stage execution
- [ ] Consider zstd compression
