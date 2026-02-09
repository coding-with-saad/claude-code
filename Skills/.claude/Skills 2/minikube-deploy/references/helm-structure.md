# Helm Chart Structure Patterns

## Chart Organization

### Service-Specific Subdirectories (Recommended for 2-4 services)

```
helm/app-name/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Production defaults
├── values-local.yaml       # Minikube overrides
├── .helmignore            # Ignore patterns
├── README.md              # Chart documentation
└── templates/
    ├── _helpers.tpl       # Template helper functions
    ├── namespace.yaml     # Dedicated namespace
    ├── configmap.yaml     # Non-sensitive config
    ├── secret.yaml        # Secret validation
    ├── service-1/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── serviceaccount.yaml
    └── service-2/
        ├── deployment.yaml
        ├── service.yaml
        └── serviceaccount.yaml
```

**Advantages**:
- Clear separation per service
- Easy to find and modify specific service configs
- Prevents naming confusion with 12+ template files
- Single atomic deployment (`helm install` deploys all services)

**When to use**: 2-4 microservices with shared lifecycle

### Flat Structure (For single service)

```
helm/app-name/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── namespace.yaml
    ├── deployment.yaml
    ├── service.yaml
    └── serviceaccount.yaml
```

**When to use**: Single service deployment

### Umbrella Chart (For 5+ services)

```
helm/app-name/
├── Chart.yaml
├── charts/               # Subcharts
│   ├── service-1/
│   ├── service-2/
│   └── service-3/
└── values.yaml
```

**When to use**: 5+ services, independent release cycles

## Template Helpers (_helpers.tpl)

Essential helper patterns:

```yaml
{{/*
App name
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service-specific labels (repeat for each service)
*/}}
{{- define "app.service1.labels" -}}
{{ include "app.labels" . }}
app.kubernetes.io/component: service1
{{- end }}

{{- define "app.service1.selectorLabels" -}}
{{ include "app.selectorLabels" . }}
app.kubernetes.io/component: service1
{{- end }}

{{/*
ServiceAccount names
*/}}
{{- define "app.service1.serviceAccountName" -}}
{{- printf "%s-service1" (include "app.fullname" .) }}
{{- end }}
```

## values.yaml Structure

```yaml
# Global configuration
namespace: app-name

# ConfigMap data (non-sensitive)
configMap:
  API_HOST: "0.0.0.0"
  API_PORT: "8000"
  CORS_ORIGINS: "http://frontend:3001"

# Secret name (created separately)
secretName: app-name-secrets

# Service 1 configuration
service1:
  enabled: true
  image:
    repository: service1
    tag: latest
    pullPolicy: IfNotPresent
  service:
    type: NodePort
    port: 3000
    nodePort: 30000
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  healthCheck:
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
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false

# Service 2 configuration (repeat pattern)
service2:
  # ... same structure
```

## values-local.yaml (Minikube overrides)

```yaml
# Override for local development
configMap:
  CORS_ORIGINS: "http://localhost:30000,http://localhost:30001"

# All services use IfNotPresent for local images
service1:
  image:
    pullPolicy: IfNotPresent

service2:
  image:
    pullPolicy: IfNotPresent
```

## Best Practices

### File Organization
- **One resource per file** (except _helpers.tpl)
- **Consistent naming**: `<resource-type>.yaml` (deployment.yaml, service.yaml)
- **Group by service** for multi-service apps

### Templating
- **Use helpers** for labels, selectors, names (DRY principle)
- **Avoid logic in templates** (put complex logic in helpers)
- **Quote strings** in values: `{{ .Values.image.tag | quote }}`

### Values
- **Nested structure** for service-specific config
- **Sensible defaults** in values.yaml
- **Environment-specific** overrides in separate files

### Documentation
- **Comment helpers** with purpose
- **Document values** in README.md
- **Include examples** for common configurations
