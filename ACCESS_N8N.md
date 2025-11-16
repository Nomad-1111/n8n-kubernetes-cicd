# How to Access n8n (Local PC Deployment)

## Production-Like Access via HTTPS Ingress (Recommended) ⭐

**This is the recommended approach for production-like setup with HTTPS that survives PC standby/resume.**

### One-Time Setup

1. **Set up HTTPS with cert-manager**:
   ```powershell
   .\scripts\setup-https.ps1
   ```
   This installs cert-manager and creates self-signed certificates for all environments.

2. **Start minikube tunnel** (required for Minikube):
   ```powershell
   # Keep this running in a separate terminal
   minikube tunnel
   ```
   This makes services accessible on localhost.

3. **Add entries to hosts file** (as Administrator):
   - Open `C:\Windows\System32\drivers\etc\hosts` as Administrator
   - Add the following lines:
     ```
     127.0.0.1  n8n-dev.local
     127.0.0.1  n8n-uat.local
     127.0.0.1  n8n-prod.local
     ```
   - Save the file
   - Flush DNS cache:
     ```powershell
     ipconfig /flushdns
     ```

4. **Trust certificates (optional - removes browser warnings)**:
   ```powershell
   # Run as Administrator
   .\scripts\trust-certificates.ps1
   ```
   This installs certificates to Windows certificate store so browsers trust them.

5. **Access n8n via HTTPS**:
   - Dev: `https://n8n-dev.local`
   - UAT: `https://n8n-uat.local`
   - Prod: `https://n8n-prod.local`

   **Note**: If you didn't run the trust script, you'll need to accept the self-signed certificate warning in your browser (this is normal).

### Benefits

- ✅ **Full HTTPS encryption** - Secure TLS/SSL connections
- ✅ **Production-like setup** - Uses ingress with certificates, not port-forwarding
- ✅ **Survives PC standby/resume** - Kubernetes service, not kubectl process
- ✅ **Clean URLs with hostnames** - Professional appearance
- ✅ **No terminal windows needed** - Access directly from browser (except minikube tunnel)
- ✅ **Works like production** - Same configuration as real Kubernetes clusters
- ✅ **Secure cookies enabled** - Production-ready security

---

## Alternative: Port-Forward (Quick Testing Fallback)

**Use this if you need quick access without setup, or if ingress doesn't work:**

```powershell
# For dev environment
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678

# For UAT environment (in another terminal)
kubectl port-forward -n n8n-uat svc/workflow-api-svc 5679:5678

# For Prod environment (in another terminal)
kubectl port-forward -n n8n-prod svc/workflow-api-svc 5680:5678
```

Then access:
- Dev: `http://localhost:5678`
- UAT: `http://localhost:5679`
- Prod: `http://localhost:5680`

**Note**: Keep the PowerShell window open while using n8n. Press `Ctrl+C` to stop port-forwarding.

**Helper Script**: A helper script `start-n8n-port-forwards.ps1` is available in the repository root to start all port-forwards automatically.

**⚠️ Limitation**: Port-forwarding terminates when your PC goes to standby, requiring manual restart.

---

## Solution Options (Detailed)

---

### Option 3: Use Ingress Controller IP Directly

1. **Get the ingress controller IP**:
   ```powershell
   kubectl get ingress -n n8n-dev n8n-ingress
   ```

2. **Get the ingress controller service IP**:
   ```powershell
   kubectl get svc -A | findstr nginx
   # Look for EXTERNAL-IP or LoadBalancer IP
   ```

3. **Access using IP with Host header**:
   - Use a tool like Postman or curl:
     ```powershell
     curl -H "Host: n8n-dev.local" http://<INGRESS_IP>
     ```
   - Or use browser extensions that allow setting custom headers

---

### Option 4: Use NodePort Service (Alternative)

If ingress isn't working, you can temporarily change the service type:

1. **Update values file**:
   ```yaml
   service:
     type: NodePort
     port: 5678
     targetPort: 5678
   ```

2. **Get the NodePort**:
   ```powershell
   kubectl get svc -n n8n-dev workflow-api-svc
   ```

3. **Access**: `http://localhost:<NODEPORT>` or `http://<NODE_IP>:<NODEPORT>`

---

## Finding Your Ingress Controller

### Check if Ingress Controller is Running

```powershell
# Check ingress controller pods
kubectl get pods -A | findstr ingress

# Check ingress controller service
kubectl get svc -A | findstr ingress

# Check ingress resources
kubectl get ingress -A
```

### Common Ingress Controller Locations

- **NGINX Ingress**: Usually in `ingress-nginx` namespace
- **Docker Desktop**: May be in `kube-system` or `default` namespace
- **Minikube**: Use `minikube service` command

### Get Ingress Controller IP

```powershell
# For LoadBalancer type
kubectl get svc -n ingress-nginx ingress-nginx-controller

# For NodePort type (Docker Desktop)
kubectl get nodes -o wide
# Use the node's InternalIP or ExternalIP
```

---

## Verify n8n is Running

Before trying to access, verify the deployment is working:

```powershell
# Check pods
kubectl get pods -n n8n-dev

# Check service
kubectl get svc -n n8n-dev

# Check ingress
kubectl get ingress -n n8n-dev

# Check pod logs
kubectl logs -n n8n-dev -l app=n8n-api
```

---

## Troubleshooting

### Port-Forward Timeout (FIXED)

**Status**: ✅ **RESOLVED** - All environments now accessible via port-forward

**Previous Issue**:
- Port-forward was timing out for UAT and prod environments
- Service endpoints were empty (`<none>`)
- Root cause: Pod labels didn't match service selector requirements

**Fix Applied**:
- Pod labels updated to include required Kubernetes standard labels:
  - `app.kubernetes.io/name: n8n`
  - `app.kubernetes.io/instance: n8n-<env>`
  - `app.kubernetes.io/part-of: n8n`
- Service endpoints now properly populated with pod IPs
- Port-forwarding works for all three environments

**Current Access**:
```powershell
# Dev (port 5678)
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
# Access: http://localhost:5678

# UAT (port 5679)
kubectl port-forward -n n8n-uat svc/workflow-api-svc 5679:5678
# Access: http://localhost:5679

# Prod (port 5680)
kubectl port-forward -n n8n-prod svc/workflow-api-svc 5680:5678
# Access: http://localhost:5680
```

**If port-forward still times out**:

1. **Check service endpoints**:
   ```powershell
   kubectl get endpoints -n n8n-uat workflow-api-svc
   kubectl get endpoints -n n8n-prod workflow-api-svc
   ```
   - Should show pod IPs, not empty

2. **Verify pod labels**:
   ```powershell
   kubectl get pods -n n8n-uat -o jsonpath='{.items[0].metadata.labels}' | ConvertFrom-Json | Format-List
   ```
   - Should include `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/part-of`

3. **Verify service selector**:
   ```powershell
   kubectl get svc -n n8n-uat workflow-api-svc -o yaml | Select-String -Pattern "selector:" -Context 0,5
   ```
   - Should match pod labels

4. **Check for network policies**:
   ```powershell
   kubectl get networkpolicies -n n8n-uat
   kubectl get networkpolicies -n n8n-prod
   ```

### Ingress Not Created

If ingress doesn't exist:
```powershell
kubectl get ingress -n n8n-dev
```

If it's missing, check:
1. Ingress is enabled in values: `ingress.enabled: true`
2. Argo CD has synced the changes
3. Helm chart rendered correctly

### Ingress Controller Not Installed

If you don't have an ingress controller on your local PC:

**For Docker Desktop (Local PC)**:
1. Make sure Kubernetes is enabled in Docker Desktop settings
2. Install NGINX Ingress:
   ```powershell
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   ```
3. Wait for it to be ready:
   ```powershell
   kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
   ```
4. Get the service details:
   ```powershell
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```
   - For Docker Desktop, it's usually accessible via `localhost` or `127.0.0.1`

**For Minikube**:
```powershell
minikube addons enable ingress
minikube service ingress-nginx -n ingress-nginx
```

**Note**: For local PC development, **port-forwarding (Option 2) is usually easier** than setting up ingress.

### Trusting Self-Signed Certificates

**To remove browser security warnings**, install certificates to Windows certificate store:

```powershell
# Run as Administrator
.\scripts\trust-certificates.ps1
```

This will:
- Export certificates from Kubernetes
- Install them to Windows Trusted Root Certification Authorities
- Remove browser security warnings

After installation, **restart your browser completely** and access URLs will work without warnings.

### Troubleshooting Ingress Access

**If you can't access via `https://n8n-dev.local`:**

1. **Verify minikube tunnel is running**:
   ```powershell
   # Check if tunnel process is running
   # You should have a terminal with: minikube tunnel
   # If not, start it: minikube tunnel
   ```

2. **Verify ingress controller service**:
   ```powershell
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```
   Should show `LoadBalancer` type with `EXTERNAL-IP: 127.0.0.1`. If not, configure it:
   ```powershell
   kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"LoadBalancer"}}'
   # Then start: minikube tunnel
   ```

2. **Verify hosts file entries**:
   - Open `C:\Windows\System32\drivers\etc\hosts` as Administrator
   - Verify these lines exist:
     ```
     127.0.0.1  n8n-dev.local
     127.0.0.1  n8n-uat.local
     127.0.0.1  n8n-prod.local
     ```
   - No extra spaces, IP address first, then hostname
   - Flush DNS: `ipconfig /flushdns`

3. **Check if DNS resolves**:
   ```powershell
   ping n8n-dev.local
   # Should resolve to 127.0.0.1
   ```

4. **Check if port 443 (HTTPS) is accessible**:
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 443
   # Should succeed
   ```

5. **Check if certificates are ready**:
   ```powershell
   kubectl get certificates -A
   # Should show certificates with READY: True
   ```

6. **Verify ingress controller is running**:
   ```powershell
   kubectl get pods -n ingress-nginx
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```

7. **Check ingress resources**:
   ```powershell
   kubectl get ingress -n n8n-dev
   kubectl describe ingress -n n8n-dev n8n-ingress
   ```

8. **Check Windows Firewall**:
   - May be blocking connections
   - Temporarily disable to test

**If ingress still doesn't work**, use port-forwarding as a fallback (see Alternative section above).

---

## Quick Reference Commands (Local PC)

```powershell
# ⭐ HTTPS Ingress Access (Production-like - RECOMMENDED)
# One-time setup:
.\scripts\setup-https.ps1
minikube tunnel  # Keep running in separate terminal
.\scripts\trust-certificates.ps1  # Run as Administrator (optional)

# Then access:
# Dev:  https://n8n-dev.local
# UAT:  https://n8n-uat.local
# Prod: https://n8n-prod.local

# Alternative: Port forward (quick testing fallback)
# Dev
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
# Access: http://localhost:5678

# UAT
kubectl port-forward -n n8n-uat svc/workflow-api-svc 5679:5678
# Access: http://localhost:5679

# Prod
kubectl port-forward -n n8n-prod svc/workflow-api-svc 5680:5678
# Access: http://localhost:5680

# Check if n8n pods are running
kubectl get pods -n n8n-dev

# View n8n logs
kubectl logs -n n8n-dev -l app=n8n-api --tail=50

# Check if service is accessible
kubectl get endpoints -n n8n-dev workflow-api-svc

# Check ingress status (if using ingress)
kubectl describe ingress -n n8n-dev n8n-ingress

# Get ingress controller IP (for Docker Desktop)
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check all services in namespace
kubectl get svc -n n8n-dev

# Restart n8n deployment (if needed)
kubectl rollout restart deployment/n8n-api -n n8n-dev
```

## Local PC Specific Notes

### Docker Desktop Kubernetes:
- Services are accessible via `localhost` when using port-forward
- Ingress controller may need to be installed separately
- Use port-forwarding for easiest access

### Checking Your Setup:
```powershell
# Verify Kubernetes is running
kubectl cluster-info

# Check your current context
kubectl config current-context

# List all namespaces
kubectl get namespaces

# Check n8n namespace exists
kubectl get ns n8n-dev
```

---

## Recommended Approach for Local PC

Since you're deploying on your **local PC**, here's the recommended approach:

### For Quick Testing (Recommended):
**Use Option 2 (Port-Forward)** - It's the simplest:
```powershell
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
```
Then access: `http://localhost:5678`

### For Production-Like Testing:
**Note**: On Docker Desktop, ingress URLs may not work due to port 80 limitations. Port-forwarding is still recommended.

If you need to test ingress configuration:
1. Install ingress controller (if not already installed)
2. Add entries to hosts file pointing to `127.0.0.1`
3. Access via `http://n8n-dev.local` (may timeout on Docker Desktop)
4. If it times out, use port-forwarding instead

### Why Port-Forward is Better for Docker Desktop:
- ✅ Works immediately - no configuration needed
- ✅ No need to install/configure ingress controller
- ✅ No need to modify hosts file
- ✅ No DNS issues
- ✅ No port 80 accessibility problems
- ✅ Can run multiple environments on different ports
- ✅ Most reliable method for Docker Desktop

### When to Use Ingress on Local PC:
- Testing ingress configuration before production
- Testing TLS/SSL certificates
- Testing domain-based routing
- Multiple services that need proper routing

---

## Helper Script

A PowerShell helper script is available to start port-forwards for all environments:

```powershell
# Run from repository root
.\start-n8n-port-forwards.ps1
```

This script will:
- Start port-forward for dev environment (port 5678)
- Start port-forward for UAT environment (port 5679)
- Start port-forward for prod environment (port 5680)
- Open separate PowerShell windows for each

Then access:
- Dev: `http://localhost:5678`
- UAT: `http://localhost:5679`
- Prod: `http://localhost:5680`

---

## Docker Desktop Limitations

**Important**: Docker Desktop has known limitations with ingress:

1. **Port 80 Not Accessible**: Port 80 is typically not accessible on Docker Desktop, which prevents ingress URLs from working even with proper configuration.

2. **Workaround**: Use port-forwarding (Option 2) - it's the most reliable method and works immediately.

3. **Ingress Still Useful**: Ingress resources are still created and configured correctly - they just can't be accessed via port 80 on Docker Desktop. This is fine for development, and the configuration will work correctly in production Kubernetes clusters.

---

*Last Updated: November 2025*

