# Common Minikube Deployment Issues

Quick reference for troubleshooting common problems during Minikube deployments.

## Table of Contents

1. [Image Pull Issues](#image-pull-issues)
2. [Networking Issues](#networking-issues)
3. [External Database Connectivity](#external-database-connectivity)
4. [Pod Crashes](#pod-crashes)
5. [Helm Issues](#helm-issues)
6. [Resource Issues](#resource-issues)
7. [Windows-Specific Issues](#windows-specific-issues)

---

## Image Pull Issues

### ImagePullBackOff / ErrImagePull

**Symptom:** Pod stuck in `ImagePullBackOff` or `ErrImagePull` state.

**Cause:** Image was built on host Docker, not Minikube's Docker.

**Solution:**
```bash
# Switch to Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild image
docker build -t myapp:latest .

# Verify image exists in Minikube
docker images | grep myapp
```

### Image Not Found After Rebuild

**Cause:** Shell session lost Docker env configuration.

**Solution:** Run `eval $(minikube docker-env)` in EVERY new terminal before building.

---

## Networking Issues

### Cannot Access Service Externally

**Symptom:** `curl: (7) Failed to connect`

**Solutions:**

1. **Use port-forward (recommended):**
   ```bash
   kubectl port-forward svc/myservice 8080:8080 -n mynamespace
   ```

2. **Use NodePort:**
   ```yaml
   # In values.yaml
   service:
     type: NodePort
     nodePort: 30000
   ```
   Then access via: `minikube ip`:30000

3. **Use minikube tunnel:**
   ```bash
   minikube tunnel  # Run in separate terminal (requires admin/sudo)
   ```

### DNS Resolution Fails Inside Pods

**Symptom:** Pods can't resolve other service names.

**Solution:**
```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Verify DNS
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes
```

---

## External Database Connectivity

### IPv6/ETIMEDOUT to External Services (Neon, Supabase, etc.)

**Symptom:** Connection timeouts to external databases from pods.

**Cause:** Minikube lacks IPv6 routing, but Node.js/fetch tries IPv6 first.

**Solutions:**

1. **Force IPv4 in Node.js:**
   ```javascript
   // Add at top of db connection file
   import dns from "dns";
   dns.setDefaultResultOrder("ipv4first");
   ```

2. **Use custom fetch for Neon:**
   ```javascript
   import { neonConfig } from "@neondatabase/serverless";
   import https from "https";

   // Custom fetch that forces IPv4
   neonConfig.fetchFunction = async (url, init) => {
     // Implementation that uses https with family: 4
   };
   ```

3. **Add hostAliases (less reliable):**
   ```yaml
   # In deployment.yaml
   spec:
     template:
       spec:
         hostAliases:
           - ip: "x.x.x.x"  # Resolved IPv4
             hostnames:
               - "your-db-host.com"
   ```

### SSL Certificate Errors

**Symptom:** `UNABLE_TO_VERIFY_LEAF_SIGNATURE`

**Solution (development only):**
```bash
# NOT for production!
kubectl set env deployment/myapp NODE_TLS_REJECT_UNAUTHORIZED=0
```

---

## Pod Crashes

### CrashLoopBackOff

**Diagnosis:**
```bash
# Check logs
kubectl logs <pod-name> -n <namespace>

# Check previous container logs
kubectl logs <pod-name> -n <namespace> --previous

# Check events
kubectl describe pod <pod-name> -n <namespace>
```

**Common Causes:**

1. **Missing environment variables:**
   ```bash
   kubectl get configmap -n <namespace>
   kubectl get secret -n <namespace>
   ```

2. **Health probe fails:**
   - Wrong probe path (use `/` or actual health endpoint)
   - Probe runs before app is ready (increase `initialDelaySeconds`)

3. **Out of memory:**
   ```yaml
   resources:
     limits:
       memory: 512Mi  # Increase if needed
   ```

### OOMKilled

**Symptom:** Pod restarts with reason `OOMKilled`

**Solution:**
```yaml
resources:
  limits:
    memory: 512Mi  # Increase memory limit
  requests:
    memory: 256Mi
```

---

## Helm Issues

### Release Already Exists

**Symptom:** `Error: cannot re-use a name that is still in use`

**Solution:**
```bash
# Upgrade instead of install
helm upgrade --install myapp ./helm/myapp -n mynamespace

# Or uninstall first
helm uninstall myapp -n mynamespace
```

### Values Not Applied

**Cause:** Using wrong values file or syntax error.

**Solution:**
```bash
# Verify values
helm template myapp ./helm/myapp -f values.yaml | less

# Check for YAML errors
helm lint ./helm/myapp
```

### Namespace Doesn't Exist

**Solution:**
```bash
kubectl create namespace mynamespace
# Or add --create-namespace flag
helm install myapp ./helm/myapp -n mynamespace --create-namespace
```

---

## Resource Issues

### Minikube Out of Disk

**Symptom:** Pods stuck in `Pending`, events show disk pressure.

**Solution:**
```bash
# Check disk usage
minikube ssh "df -h"

# Clean up unused images
minikube ssh "docker system prune -a"

# Or increase disk on recreate
minikube delete
minikube start --disk-size=50g
```

### Minikube Out of Memory

**Symptom:** Nodes show `MemoryPressure`

**Solution:**
```bash
# Recreate with more memory
minikube delete
minikube start --memory=8192
```

### Insufficient CPU

**Solution:**
```bash
minikube delete
minikube start --cpus=4
```

---

## Windows-Specific Issues

### eval $(minikube docker-env) Fails in PowerShell

**Solution for PowerShell:**
```powershell
& minikube docker-env --shell powershell | Invoke-Expression
```

**Solution for CMD:**
```cmd
@FOR /f "tokens=*" %i IN ('minikube docker-env --shell cmd') DO @%i
```

### Docker Build Context Too Large

**Cause:** Windows paths or large node_modules included.

**Solution:**
Ensure `.dockerignore` exists:
```
node_modules
.git
*.log
```

### Line Ending Issues

**Symptom:** Scripts fail with `\r` errors.

**Solution:**
```bash
# Convert line endings
sed -i 's/\r$//' script.sh

# Or configure Git
git config core.autocrlf input
```

### Path Issues in Git Bash

**Symptom:** Paths like `/c/Users` not recognized.

**Solution:**
```bash
# Use Windows-style paths
DOCKER_CERT_PATH="C:/Users/name/.minikube/certs"

# Or use MSYS path conversion
export MSYS_NO_PATHCONV=1
```

---

## Quick Diagnostic Commands

```bash
# Overall cluster status
minikube status
kubectl cluster-info

# Pod status
kubectl get pods -n <namespace> -o wide

# Events (shows errors)
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n <namespace>
kubectl top nodes

# Describe for details
kubectl describe pod <pod> -n <namespace>
kubectl describe svc <service> -n <namespace>

# Logs
kubectl logs <pod> -n <namespace> --tail=50
kubectl logs <pod> -n <namespace> -c <container>  # Specific container

# Enter pod for debugging
kubectl exec -it <pod> -n <namespace> -- /bin/sh
```

---

## Prevention Checklist

Before deploying, verify:

- [ ] `eval $(minikube docker-env)` executed in current terminal
- [ ] All images built with correct tags
- [ ] `.env` file exists with required secrets
- [ ] Namespace exists or `--create-namespace` used
- [ ] Sufficient resources (4GB+ RAM, 20GB+ disk)
- [ ] Health probe paths match actual endpoints
- [ ] Service ports match container EXPOSE ports
