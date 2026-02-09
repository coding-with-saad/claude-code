# Secret Management Patterns

## Strategy: Manual kubectl create secret

**Rationale**: Keeps secrets out of version control, provides explicit provisioning, Kubernetes-native.

## Creating Secrets

### Basic Secret Creation

```bash
kubectl create secret generic app-secrets \
  --namespace=app-namespace \
  --from-literal=DATABASE_URL='postgresql://user:pass@host:5432/db' \
  --from-literal=API_KEY='sk-xxx' \
  --from-literal=AUTH_SECRET='32-char-random-string'
```

### From File

```bash
kubectl create secret generic app-secrets \
  --namespace=app-namespace \
  --from-env-file=.env.secrets
```

### Verify Secret

```bash
kubectl get secret app-secrets -n app-namespace
kubectl describe secret app-secrets -n app-namespace
```

## Using Secrets in Deployments

### Environment Variable Injection (Recommended)

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DATABASE_URL
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: API_KEY
```

**Benefits**:
- Values injected as environment variables
- Secret never in plaintext in templates
- Helm chart remains shareable

### Volume Mount (For files)

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        volumeMounts:
        - name: secrets
          mountPath: "/etc/secrets"
          readOnly: true
      volumes:
      - name: secrets
        secret:
          secretName: app-secrets
```

**Use for**: Certificate files, SSH keys, config files

## Secret Validation Template

Create `templates/secret.yaml` that validates but doesn't create:

```yaml
{{/*
NOTE: This file validates secret existence only.
The secret must be created manually BEFORE Helm install.

Create with:
kubectl create secret generic {{ .Values.secretName }} \
  --namespace={{ .Values.namespace }} \
  --from-literal=DATABASE_URL='postgresql://...' \
  --from-literal=API_KEY='...'
*/}}
{{- $secretName := .Values.secretName }}
{{- $secret := (lookup "v1" "Secret" .Values.namespace $secretName) }}
{{- if and (not $secret) .Release.IsInstall }}
{{- fail (printf "Secret '%s' must be created in namespace '%s' before installing. See templates/secret.yaml for instructions." $secretName .Values.namespace) }}
{{- end }}
```

**Purpose**: Fail-fast with clear instructions if secret missing

## Deployment Script Integration

```bash
#!/bin/bash
# In deploy script

NAMESPACE="app-namespace"
SECRET_NAME="app-secrets"

# Check if secret exists
if ! kubectl get secret $SECRET_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ ERROR: Secret '$SECRET_NAME' not found"
    echo "Create with:"
    echo ""
    echo "kubectl create secret generic $SECRET_NAME -n $NAMESPACE \\"
    echo "  --from-literal=DATABASE_URL='...' \\"
    echo "  --from-literal=API_KEY='...'"
    exit 1
fi

echo "✅ Secrets found"
```

## ConfigMap vs Secret Decision Rule

| Use ConfigMap | Use Secret |
|--------------|------------|
| Non-sensitive URLs | Database credentials |
| Port numbers | API keys |
| Feature flags | OAuth tokens |
| CORS origins | Certificates |
| Log levels | Private keys |

**Rule**: If leaking it would be a security incident, use Secret.

## Secret Rotation

### Update Secret

```bash
# Delete old secret
kubectl delete secret app-secrets -n app-namespace

# Create new secret
kubectl create secret generic app-secrets \
  --namespace=app-namespace \
  --from-literal=DATABASE_URL='new-url'

# Restart pods to pick up new secret
kubectl rollout restart deployment app -n app-namespace
```

### Automated Rotation (Production)

For production, use **External Secrets Operator**:
- Syncs secrets from cloud key vaults (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)
- Automatic rotation
- Audit logging
- Not needed for local Minikube development

## Security Best Practices

### DO
- ✅ Create secrets manually via kubectl
- ✅ Use secretKeyRef for injection
- ✅ Add secret template validation
- ✅ Document required secret keys
- ✅ Use separate secrets per namespace
- ✅ Generate strong random values (32+ characters)

### DON'T
- ❌ Commit secrets to values.yaml
- ❌ Store secrets in values-local.yaml
- ❌ Use plaintext env vars in templates
- ❌ Share secrets across namespaces
- ❌ Use imagePullSecrets for public images
- ❌ Log secret values

## Generating Secrets

```bash
# Random 32-character string
openssl rand -base64 32

# UUID
uuidgen

# Hex string
openssl rand -hex 16
```

## Troubleshooting

### Secret not found
```bash
kubectl get secrets -n app-namespace
kubectl describe secret app-secrets -n app-namespace
```

### Pod can't read secret
```bash
kubectl describe pod <pod-name> -n app-namespace
# Look for "MountVolume.SetUp failed" or "secret not found"
```

### View secret values (debugging only)
```bash
kubectl get secret app-secrets -n app-namespace -o yaml
kubectl get secret app-secrets -n app-namespace -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

**Warning**: Never log or expose secret values in production.
