# Language-Specific Dockerfile Patterns

Production-ready Dockerfile patterns for each language/framework.

## Table of Contents

- [Node.js Patterns](#nodejs-patterns)
  - [Next.js Platinum+](#nextjs-platinum-pattern)
  - [Next.js with Bun](#nextjs-with-bun)
  - [Express.js](#expressjs-platinum-pattern)
- [Python Patterns](#python-patterns)
  - [FastAPI with UV](#fastapi-with-uv)
  - [FastAPI with PDM](#fastapi-with-pdm)
  - [FastAPI with Poetry](#fastapi-with-poetry)
  - [Django](#django-platinum-pattern)
- [Go Patterns](#go-patterns)
  - [Standard Go Service](#standard-go-service)
  - [Go with cgo](#go-with-cgo-dependencies)
- [Java Patterns](#java-patterns)
  - [Spring Boot](#spring-boot-platinum-pattern)
  - [Micronaut](#micronaut-platinum-pattern)
- [Rust Patterns](#rust-patterns)
  - [Standard Rust Service](#standard-rust-service)
  - [Rust with Diesel/PostgreSQL](#rust-with-dieselpostgresql)

---

## Node.js Patterns

### Next.js Platinum+ Pattern

Production-ready with standalone output:

```dockerfile
# syntax=docker/dockerfile:1

# Stage 1: Dependencies (cached)
FROM node:22-slim AS deps
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm-store,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile

# Stage 2: Builder
FROM node:22-slim AS builder
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG DATABASE_URL=postgresql://user:pass@localhost:5432/dummy
ENV DATABASE_URL=$DATABASE_URL

ARG NEXT_PUBLIC_API_URL=http://localhost:8000/api
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_TELEMETRY_DISABLED=1

RUN --mount=type=cache,id=pnpm-store,target=/root/.pnpm-store \
    pnpm build
RUN test -f .next/standalone/server.js
ENV DATABASE_URL=""

# Stage 3: Runtime (minimal, secure)
FROM node:22-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/api/health') \
    .then(r => r.ok ? process.exit(0) : process.exit(1)) \
    .catch(() => process.exit(1))"

CMD ["node", "server.js"]
```

**Required next.config.js:**
```javascript
module.exports = { output: 'standalone' }
```

### Next.js with Bun

```dockerfile
# syntax=docker/dockerfile:1

FROM oven/bun:1-slim AS deps
WORKDIR /app
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile

FROM oven/bun:1-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG DATABASE_URL=dummy
ENV DATABASE_URL=$DATABASE_URL
RUN bun run build
ENV DATABASE_URL=""

FROM oven/bun:1-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
ENV NODE_ENV=production PORT=3000 HOSTNAME=0.0.0.0
COPY --from=builder /app/public ./public
COPY --from=builder --chown=app:app /app/.next/standalone ./
COPY --from=builder --chown=app:app /app/.next/static ./.next/static
USER app
EXPOSE 3000
HEALTHCHECK CMD bun -e "fetch('http://127.0.0.1:3000/api/health').then(r => r.ok ? process.exit(0) : process.exit(1))"
CMD ["bun", "server.js"]
```

### Express.js Platinum Pattern

```dockerfile
# syntax=docker/dockerfile:1

FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,id=npm,target=/root/.npm \
    npm ci --only=production && npm cache clean --force

FROM node:22-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=app:app . .
USER app
EXPOSE 3000
HEALTHCHECK CMD node -e "fetch('http://127.0.0.1:3000/health')"
CMD ["node", "src/server.js"]
```

---

## Python Patterns

### FastAPI with UV

Modern Python package manager (recommended):

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.13-slim AS builder
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_HTTP_TIMEOUT=300

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "uv==0.5.*"
COPY pyproject.toml uv.lock* ./
RUN uv pip install --system --no-cache -e .
COPY src ./src

FROM python:3.13-slim AS runtime
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src \
    PORT=8000

RUN groupadd --system --gid 1001 apiuser && \
    useradd --system --uid 1001 --gid apiuser apiuser

COPY --from=builder /usr/local/lib/python3.13/site-packages \
                    /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --chown=apiuser:apiuser src/ ./src/

USER apiuser
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health').read()"

CMD ["gunicorn", "src.main:app", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "--workers", "2"]
```

### FastAPI with PDM

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.13-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir pdm
COPY pyproject.toml pdm.lock ./
RUN --mount=type=cache,id=pdm,target=/root/.cache/pdm \
    pdm install --prod --no-editable

FROM python:3.13-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/app/.venv/bin:$PATH"
COPY --from=builder /app/.venv /app/.venv
COPY --chown=app:app . .
USER app
EXPOSE 8000
HEALTHCHECK CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### FastAPI with Poetry

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.13-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir poetry
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache
COPY pyproject.toml poetry.lock ./
RUN --mount=type=cache,target=$POETRY_CACHE_DIR \
    poetry install --only=main --no-root

FROM python:3.13-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/app/.venv/bin:$PATH"
COPY --from=builder /app/.venv /app/.venv
COPY --chown=app:app . .
USER app
EXPOSE 8000
HEALTHCHECK CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Django Platinum Pattern

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install uv
COPY requirements.txt ./
RUN uv venv /opt/venv
RUN --mount=type=cache,id=uv,target=/root/.cache/uv \
    uv pip install --no-cache -r requirements.txt

FROM python:3.12-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
ENV PATH="/opt/venv/bin:$PATH" DJANGO_SETTINGS_MODULE=app.settings.production PYTHONUNBUFFERED=1
COPY --from=builder /opt/venv /opt/venv
COPY --chown=app:app . .
RUN python manage.py collectstatic --noinput
USER app
EXPOSE 8000
HEALTHCHECK CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/')"
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app.wsgi:application"]
```

---

## Go Patterns

### Standard Go Service

Uses distroless for minimal attack surface:

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.22-slim AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
ARG TARGETOS=linux
ARG TARGETARCH=amd64
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-w -s -X main.version=${VERSION}" \
    -o /app/server .

FROM gcr.io/distroless/static-debian12 AS runner
WORKDIR /
COPY --from=builder /app/server /server
USER 65532:65532
EXPOSE 8080
HEALTHCHECK CMD ["/server", "-healthcheck"]
CMD ["/server"]
```

### Go with cgo Dependencies

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.22-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
RUN go build -ldflags="-w -s -X main.version=${VERSION}" -o /app/server .

FROM debian:12-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY --from=builder /app/server /server
USER app
EXPOSE 8080
HEALTHCHECK CMD ./server -healthcheck
CMD ["./server"]
```

---

## Java Patterns

### Spring Boot Platinum Pattern

```dockerfile
# syntax=docker/dockerfile:1

FROM eclipse-temurin:21-jdk-slim AS builder
WORKDIR /app
COPY pom.xml .
RUN --mount=type=cache,id=maven,target=/root/.m2 \
    mvn dependency:go-offline
COPY src ./src
ARG VERSION=0.0.1
RUN mvn clean package -DskipTests -Drevision=${VERSION}

FROM eclipse-temurin:21-jre-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
USER app
EXPOSE 8080
HEALTHCHECK --start-period=60s \
  CMD java -jar app.jar --actuator.health.probes.enabled=true
CMD ["java", "-jar", "app.jar"]
```

### Micronaut Platinum Pattern

```dockerfile
# syntax=docker/dockerfile:1

FROM eclipse-temurin:21-jdk-slim AS builder
WORKDIR /app
COPY build.gradle gradlew ./
RUN chmod +x gradlew
COPY src ./src
RUN ./gradlew installDist --no-daemon

FROM eclipse-temurin:21-jre-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY --from=builder /app/build/install/app/lib ./lib
COPY --from=builder /app/build/install/app/bin/app ./app
USER app
EXPOSE 8080
CMD ["./app"]
```

---

## Rust Patterns

### Standard Rust Service

```dockerfile
# syntax=docker/dockerfile:1

FROM rust:1.77-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src
COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:12-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY --from=builder /app/target/release/app ./app
USER app
EXPOSE 8080
HEALTHCHECK CMD ./app --healthcheck
CMD ["./app"]
```

### Rust with Diesel/PostgreSQL

```dockerfile
# syntax=docker/dockerfile:1

FROM rust:1.77-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libpq-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src
COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:12-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
RUN apt-get update && apt-get install -y libpq5 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/app ./app
USER app
EXPOSE 8080
HEALTHCHECK CMD ./app --healthcheck
CMD ["./app"]
```
