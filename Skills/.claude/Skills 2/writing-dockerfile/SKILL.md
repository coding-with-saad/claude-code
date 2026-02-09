---
name: writing-dockerfile
description: |
  Generates secure, production-ready Dockerfiles with multi-stage builds and security hardening.
  Use when Claude needs to write Dockerfiles for containerized applications.
---

# Dockerfile Authoring Skill

## What This Skill Does

Creates enterprise-grade, production-ready Dockerfiles following the Universal Dockerfile Platinum+ Standard with:
- Multi-stage builds (deps → builder → runner)
- BuildKit 1.20+ features (cache mounts, secret mounts, heredocs)
- Security hardening (non-root, distroless, read-only FS)
- Cloud-native compatibility (K8s probes, 12-factor)

## What This Skill Does NOT Do

- Write docker-compose.yml files (use containerization skill)
- Create Kubernetes manifests or Helm charts
- Optimize images for size only (security takes priority)

---

## Before Implementation

Gather context to ensure successful implementation:

| Source | Gather |
|--------|--------|
| **Codebase** | Package manager (package.json, pyproject.toml, go.mod), framework, existing Dockerfile |
| **Conversation** | Target environment, build-time secrets, runtime secrets, base image preference |
| **Skill References** | Language, security, BuildKit, CI/CD patterns from `references/` |
| **User Guidelines** | Team conventions, registry requirements, compliance constraints |

Only ask user for THEIR specific requirements (domain expertise is in this skill).

---

## Quick Pattern Selection

```
Language?
├─ Node.js → Framework?
│  ├─ Next.js → references/language-patterns.md#nextjs-platinum-pattern
│  ├─ Express → references/language-patterns.md#expressjs-platinum-pattern
│  └─ Bun runtime → references/language-patterns.md#nextjs-with-bun
├─ Python → Package Manager?
│  ├─ uv → references/language-patterns.md#fastapi-with-uv
│  ├─ poetry → references/language-patterns.md#fastapi-with-poetry
│  ├─ pdm → references/language-patterns.md#fastapi-with-pdm
│  └─ Django → references/language-patterns.md#django-platinum-pattern
├─ Go → CGO?
│  ├─ No → references/language-patterns.md#standard-go-service (distroless)
│  └─ Yes → references/language-patterns.md#go-with-cgo-dependencies
├─ Java → Framework?
│  ├─ Spring Boot → references/language-patterns.md#spring-boot-platinum-pattern
│  └─ Micronaut → references/language-patterns.md#micronaut-platinum-pattern
└─ Rust → Database?
   ├─ PostgreSQL → references/language-patterns.md#rust-with-dieselpostgresql
   └─ None → references/language-patterns.md#standard-rust-service
```

## Grep Patterns for References

```bash
# Language patterns
grep -n "### Node.js\|### Python\|### Go\|### Java\|### Rust" references/language-patterns.md

# Security patterns
grep -n "Non-Root\|Secret\|Healthcheck\|Anti-Patterns" references/security-patterns.md

# BuildKit cache mounts
grep -n "mount=type=cache\|--security\|--parents\|heredoc" references/buildkit-features.md

# CI/CD patterns
grep -n "GitHub Actions\|Kubernetes\|dockerignore" references/cicd-patterns.md
```

---

## Overview

Creates Dockerfiles ensuring maximum security, determinism, and cloud-native compatibility through strict multi-stage builds, advanced BuildKit features, and modern security practices.

### Required Information (Must Have)

1. **Language & Runtime** - Node / Python / Go / Java / Rust / Bun / Deno
2. **Build Tool** - npm / pnpm / yarn / bun / uv / poetry / pdm / pip / gradle / cargo
3. **Entrypoint** - Command to start the app (or infer from codebase)

### Optional Information (Defaults Provided)

| Information | Default | Notes |
|-------------|---------|-------|
| **Framework** | Infer from codebase | Next.js, FastAPI, Spring, Django, etc. |
| **Port** | Common default | 3000 (Node), 8000 (Python), 8080 (Go/Java) |
| **Base Image** | Standard/Distroless | Distroless for prod, Standard for dev |
| **Target Level** | Platinum+ | Bronze/Silver/Gold/Platinum options available |
| **Build-time Secrets** | Dummy values | Needed only for build (e.g., DATABASE_URL) |
| **Runtime Secrets** | Runtime injection | Never baked into image |

### Handling Missing Information

When user doesn't provide specific information:

| Scenario | Action |
|----------|--------|
| Unknown framework | Infer from codebase structure (package.json scripts, imports) |
| Unknown port | Use language default (3000/Node, 8000/Python, 8080/Go-Java) |
| Unknown base image | Default: Standard for dev, Distroless for production |
| Build-time secrets | Use dummy values, add comments to replace at build time |
| Entrypoint unknown | Infer from package.json `[scripts.start]` or similar |

**Principle**: Make reasonable defaults but add comments indicating where user should customize.

```dockerfile
# TODO: Update port if your app uses different default
EXPOSE 3000

# TODO: Replace with your actual start command
CMD ["node", "server.js"]
```

## 🏗️ Phase 2: Apply Platinum Standards

### 2.1 Base Image Rules
- **ONLY use**: Docker Official Images or well-known vendor images (node, python, eclipse-temurin)
- **Prefer**: slim variants, Debian (bookworm/bullseye)
- **NEVER use**: latest tags, random GitHub images
- **Always pin**: Runtime MAJOR version, optionally MINOR for Platinum

### 2.2 Multi-Stage Build (MANDATORY)
Every production Dockerfile MUST include:
- `deps` – dependency installation
- `builder` – compilation / build
- `runner` – minimal runtime
No exceptions.

### 2.3 Dependency Installation Rules
- Copy ONLY dependency manifests first
- Lockfiles are mandatory
- Fail if lockfile mismatch

Examples:
```dockerfile
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen
```

### 2.4 Build-time Environment Variables
**Golden Rule**: If a variable is needed ONLY for build, it MUST NOT exist in runtime image.

Pattern:
```dockerfile
ARG DATABASE_URL=dummy
ENV DATABASE_URL=$DATABASE_URL
RUN build-command
ENV DATABASE_URL=""  # Clear after build
```

- `NEXT_PUBLIC_*` → build-time allowed
- Secrets → NEVER copied to runtime

### 2.5 Runtime Image Rules
Runtime image MUST contain only:
- Built artifacts
- Runtime binaries

NEVER contain:
- Package managers
- Source files (unless required)
- .env files
- Build caches

### 2.6 Non-Root Execution (MANDATORY)
```dockerfile
RUN addgroup --system app && \
    adduser --system --ingroup app --shell /sbin/nologin app
USER app
```

### 2.7 Healthcheck Rules
- MUST exist
- Prefer native runtime (Node/Python)
- Avoid curl unless unavoidable

Examples:
```dockerfile
HEALTHCHECK CMD node -e "fetch('http://localhost:3000/health')..."
```

### 2.8 Entrypoint Rules
- Use exec form
- One process per container
- Correct signal handling

```dockerfile
CMD ["node", "server.js"]
```

## 🏗️ Phase 3: Security & Performance

### 3.1 Security Hardening Rules (Platinum)

- No secrets in image layers
- Minimal OS packages
- Read-only root FS compatible
- PodSecurity restricted compatible
- No privileged ports (<1024)

### 3.2 Performance & Caching Rules
- Cache dependency installs
- Use BuildKit cache mounts when available
- Minimize layer count
- Avoid invalidating cache unnecessarily

## 🏗️ Phase 4: Validation & Output

### 4.1 Validation Checklist (Agent MUST self-check)

Before outputting Dockerfile, validate:

- [ ] No latest tags
- [ ] Lockfile used
- [ ] Non-root user
- [ ] Multi-stage build
- [ ] Secrets not leaked
- [ ] Healthcheck exists
- [ ] Entrypoint is exec-form
- [ ] Runtime image minimal
- [ ] BuildKit cache mounts used
- [ ] .dockerignore recommended if needed

### 4.2 Output Requirements
- Output only the Dockerfile
- Include comments explaining each stage
- Follow Platinum+ standards unless told otherwise
- Never invent dependencies
- Never guess secrets
- Recommend .dockerignore patterns when applicable

### 4.3 Common Build Failures & Recovery

When builds fail, diagnose and suggest fixes:

| Failure | Cause | Recovery |
|---------|-------|----------|
| Lockfile mismatch | Lockfile out of sync with manifests | Run `npm install`/`uv sync` to update lockfile |
| Module not found | Missing system dependency | Add build-essential, libssl-dev, etc. to builder stage |
| Permission denied | Non-root user can't write | Fix ownership with `chown` or adjust directory permissions |
| Command not found | Binary not in PATH | Use full path or ensure installed in correct stage |
| Port already in use | Conflicts with host port | Document port usage, suggest changing with `--publish` |
| Build cache stale | Old cached layer causing issues | Suggest `docker build --no-cache` |
| Secret not found | Missing `--secret` flag | Document required build secrets in comments |

**Pattern for documenting troubleshooting in Dockerfile**:
```dockerfile
# Troubleshooting:
# - If build fails: docker build --no-cache .
# - If port conflicts: docker run -p HOSTPORT:3000 ...
# - For private packages: docker build --secret id=npm_token .
```

---

## 🚀 Phase 5: Platinum+ Advanced Features

### 5.1 Advanced BuildKit Features

#### Secret Mounts (for private registries, SSH keys)
Use secret mounts instead of ARG for sensitive build-time data:

```dockerfile
# Mount secrets without leaking them into layers
RUN --mount=type=secret,id=npm_token \
    npm config set //registry.npmjs.org/:_authToken=$(cat /run/secrets/npm_token) && \
    npm install
```

Build with: `docker build --secret id=npm_token,src=.npmrc .`

#### Bind Mounts (for efficient builds)
Mount build context without copying:

```dockerfile
# Build without copying source to image
FROM golang:1.22-slim AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
RUN --mount=type=bind,target=. \
    go build -o /app/server .
```

#### SSH Mounts (for private repos)
Access private Git repositories during build:

```dockerfile
RUN --mount=type=ssh \
    go mod download
```

Build with: `docker build --ssh default .`

### 5.2 Multi-Platform Builds

Support multiple architectures (amd64, arm64):

```dockerfile
ARG TARGETOS=linux
ARG TARGETARCH=amd64

FROM --platform=$TARGETOS/$TARGETARCH node:22-slim AS deps
# ... rest of build

# For Go, use build args
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -o /app/server .
```

Build with: `docker buildx build --platform linux/amd64,linux/arm64 .`

### 5.3 Distroless & Minimal Images

For maximum security, use distroless runtime images:

```dockerfile
# Go application with distroless
FROM gcr.io/distroless/static-debian12 AS runner
WORKDIR /
COPY --from=builder /app/server /server
USER 65532:65532
EXPOSE 8080
CMD ["/server"]
```

**Distroless variants:**
- `static-debian12` - Static binaries (Go, Rust)
- `base-debian12` - Minimal libc (Python, Node if needed)
- `cc-debian12` - With libgcc (some C++ apps)

**Alternatives:**
- Chainguard Images: `cgr.dev/chainguard/node:latest`
- Wolfi-based: `cgr.dev/chainguard/wolfi-base`

### 5.4 Production Hardening

#### Init Process for Signal Handling
Add init process for proper signal forwarding:

```dockerfile
# Using tini
RUN apt-get update && apt-get install -y tini && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
```

Or use Docker's built-in init:
```bash
docker run --init my-app
```

#### Read-Only Root Filesystem
Make runtime filesystem read-only:

```dockerfile
# Create writable directories
RUN mkdir -p /tmp /app/logs && \
    chown app:app /tmp /app/logs
USER app
# Use: docker run --read-only --tmpfs /tmp my-app
```

### 5.5 .dockerignore

Always create `.dockerignore` to reduce build context. See `references/cicd-patterns.md` for complete patterns.

---

# Reference Files

## 📚 Reference Documentation

Detailed patterns are organized by domain in `references/`:

| File | Contains |
|------|----------|
| `language-patterns.md` | Node.js, Python, Go, Java, Rust Dockerfiles |
| `security-patterns.md` | Non-root, secrets, healthchecks, anti-patterns |
| `buildkit-features.md` | Cache mounts, heredocs, multi-platform, optimization |
| `cicd-patterns.md` | GitHub Actions, Kubernetes, .dockerignore, deployment |

## 📖 External Documentation

For patterns not covered in this skill, consult official resources:

| Resource | URL | Use For |
|----------|-----|---------|
| Dockerfile Reference | https://docs.docker.com/engine/reference/builder/ | Complete Dockerfile syntax |
| BuildKit Documentation | https://docs.docker.com/build/buildkit/ | BuildKit features and cache backends |
| BuildKit Release Notes | https://github.com/moby/buildkit/releases | Latest syntax versions and features |
| Distroless Images | https://github.com/GoogleContainerTools/distroless | Distrolesless image variants and usage |
| Chainguard Images | https://edu.chainguard.dev/chainguard/chainguard-images/overview/ | Minimal alternative to distroless |
| Docker Security | https://docs.docker.com/engine/security/ | Container security best practices |
| Multi-Platform Builds | https://docs.docker.com/build/building/multi-platform/ | Cross-platform build strategies |

**Note**: Patterns in this skill reflect current best practices as of 2025. Always verify against latest official documentation.

---

## ⚠️ Critical Anti-Patterns (NEVER Do These)

### ❌ ALWAYS AVOID:
```dockerfile
# NEVER use latest tags
FROM node:latest

# NEVER run as root
USER root

# NEVER bake secrets
ENV DATABASE_URL=postgresql://user:pass@prod.db:5432/db

# NEVER include package managers in runtime
RUN npm install && npm run build

# NEVER use curl for health checks
HEALTHCHECK CMD curl http://localhost:3000/health

# NEVER use shell form for CMD
CMD node server.js
```

### ✅ ALWAYS DO:
```dockerfile
# ALWAYS pin versions
FROM node:22-slim

# ALWAYS use non-root users
RUN addgroup --system app && adduser --system --ingroup app app
USER app

# ALWAYS inject secrets at runtime
# DATABASE_URL set via docker-compose/K8s

# ALWAYS use multi-stage builds
# deps -> builder -> runner

# ALWAYS use native health checks
HEALTHCHECK CMD node -e "fetch('http://127.0.0.1:3000/health')"

# ALWAYS use exec form
CMD ["node", "server.js"]
```