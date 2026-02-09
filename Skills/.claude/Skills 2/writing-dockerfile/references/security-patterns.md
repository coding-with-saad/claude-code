# Security Patterns for Dockerfiles

Essential security hardening patterns for production Dockerfiles.

## Table of Contents

- [Non-Root User Pattern](#non-root-user-pattern)
- [Secret Management](#secret-management-pattern)
- [Healthcheck Patterns](#healthcheck-patterns)
- [BuildKit Secret Mounts](#buildkit-secret-mounts)
- [Read-Only Filesystem](#read-only-root-filesystem)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## Non-Root User Pattern

**Always run as non-root in production.**

```dockerfile
# Standard pattern (Debian/Ubuntu)
RUN addgroup --system app && \
    adduser --system --ingroup app --shell /sbin/nologin app
USER app

# With specific UID/GID (recommended for K8s)
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 --ingroup app app
USER 1001:1001

# Distroless (pre-configured nonroot user)
FROM gcr.io/distroless/static-debian12
USER 65532:65532

# Alpine Linux
RUN addgroup -S app && adduser -S -G app app
USER app
```

---

## Secret Management Pattern

**Golden Rule**: Build-time secrets MUST NOT exist in runtime image.

```dockerfile
# Build-time only (cleared after use)
ARG DATABASE_URL=postgresql://user:pass@localhost:5432/dummy
ARG SECRET_KEY=dummy-secret-for-build
ENV DATABASE_URL=$DATABASE_URL
ENV SECRET_KEY=$SECRET_KEY

RUN npm run build

# Clear immediately after build
ENV DATABASE_URL=""
ENV SECRET_KEY=""
```

**Runtime secrets**: Inject via docker-compose, Kubernetes, or cloud platform - never bake into image.

---

## Healthcheck Patterns

Use native runtime tools - avoid curl/wget dependencies.

```dockerfile
# Node.js (native fetch)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/health') \
    .then(r => r.ok ? process.exit(0) : process.exit(1)) \
    .catch(() => process.exit(1))"

# Python (native urllib)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; \
    urllib.request.urlopen('http://127.0.0.1:8000/health')"

# Go (binary flag)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/app/server", "-healthcheck"]

# Java (JAR argument)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD ["java", "-jar", "app.jar", "--healthcheck"]

# Deep health check (with DB connectivity)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD python -c "\
import urllib.request, json; \
r = urllib.request.urlopen('http://127.0.0.1:8000/health/deep'); \
data = json.loads(r.read()); \
exit(0 if data.get('status') == 'healthy' else 1)"
```

---

## BuildKit Secret Mounts

Mount secrets without leaking to image layers.

### NPM Private Registry

```dockerfile
RUN --mount=type=secret,id=npm_token \
    echo "//registry.npmjs.org/:_authToken=$(cat /run/secrets/npm_token)" > .npmrc && \
    pnpm install --frozen-lockfile && \
    rm -f .npmrc
```

Build: `docker build --secret id=npm_token,src=.npmrc .`

### SSH for Private Git Repos

```dockerfile
RUN --mount=type=ssh \
    git clone git@github.com:private/repo.git
```

Build: `docker build --ssh default .`

### Multiple Secrets

```dockerfile
RUN --mount=type=secret,id=github_token \
    --mount=type=secret,id=npm_token \
    GITHUB_TOKEN=$(cat /run/secrets/github_token) \
    NPM_TOKEN=$(cat /run/secrets/npm_token) \
    ./setup.sh
```

---

## Read-Only Root Filesystem

Make runtime filesystem read-only for enhanced security.

```dockerfile
FROM node:22-slim AS runner
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app

# Create writable directories for runtime needs
RUN mkdir -p /tmp /app/logs /app/.next/cache && \
    chown -R app:app /tmp /app/logs /app/.next/cache

COPY --from=builder --chown=app:app /app/.next/standalone ./
USER app
```

Run with: `docker run --read-only --tmpfs /tmp --tmpfs /app/logs my-app`

---

## Anti-Patterns to Avoid

### Never Do This

```dockerfile
# ❌ WRONG: Using latest tag
FROM node:latest

# ❌ WRONG: Running as root
USER root

# ❌ WRONG: Baking secrets into image
ENV DATABASE_URL=postgresql://user:pass@prod.db:5432/db

# ❌ WRONG: Package manager in runtime image
RUN npm install && npm run build

# ❌ WRONG: Missing healthcheck
# (no HEALTHCHECK instruction)

# ❌ WRONG: Using curl for health checks (adds dependency)
HEALTHCHECK CMD curl http://localhost:3000/health

# ❌ WRONG: Shell form for CMD (no signal handling)
CMD node server.js
```

### Always Do This

```dockerfile
# ✅ CORRECT: Pin versions
FROM node:22-slim

# ✅ CORRECT: Non-root user
RUN addgroup --system app && adduser --system --ingroup app app
USER app

# ✅ CORRECT: Runtime-only secrets
# DATABASE_URL injected via K8s/docker-compose

# ✅ CORRECT: Multi-stage build
# deps -> builder -> runner

# ✅ CORRECT: Native health checks
HEALTHCHECK CMD node -e "fetch('http://127.0.0.1:3000/health')"

# ✅ CORRECT: Exec form for CMD
CMD ["node", "server.js"]
```

---

## Security Checklist

Before deploying, verify:

- [ ] Non-root user (UID 1000+)
- [ ] No secrets in image layers
- [ ] No `latest` tags
- [ ] Healthcheck with native tools
- [ ] Exec form for CMD/ENTRYPOINT
- [ ] Read-only root filesystem compatible
- [ ] No privileged ports (<1024)
- [ ] Minimal attack surface (no shell in prod if possible)
- [ ] Secret mounts for build-time secrets
- [ ] PodSecurity restricted compatible
