# How to Access n8n (Local PC Deployment)

## Problem

When trying to access `n8n-dev.local`, you may get:
```
DNS_PROBE_FINISHED_NXDOMAIN
This site can't be reached
```
or
```
n8n-dev.local took too long to respond
```

**Root Cause**: On Docker Desktop, port 80 is typically not accessible, which prevents ingress URLs from working even with proper hosts file configuration. This is a known Docker Desktop limitation.

**Solution**: Use port-forwarding (Option 2) - it's the most reliable method for Docker Desktop and works immediately without any configuration.

---

## Quick Solution: Port Forward (Easiest for Local Testing)

**This is the fastest way to access n8n on your local PC:**

```powershell
# Open PowerShell and run:
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
```

Then open your browser and go to: **http://localhost:5678**

**Note**: Keep the PowerShell window open while using n8n. Press `Ctrl+C` to stop port-forwarding.

---

## Solution Options

### Option 1: Add to Windows Hosts File (⚠️ May Not Work on Docker Desktop)

**⚠️ Important**: On Docker Desktop, port 80 is typically not accessible, so ingress URLs (`http://n8n-dev.local`) may timeout even with proper hosts file configuration. **Use Option 2 (Port-Forward) instead** for reliable access.

If you still want to try ingress access:

1. **Open Notepad as Administrator**:
   - Press `Win + X`
   - Select "Windows Terminal (Admin)" or "Command Prompt (Admin)"
   - Or right-click Notepad → "Run as administrator"

2. **Open the hosts file**:
   - Navigate to: `C:\Windows\System32\drivers\etc\hosts`
   - Open with Notepad

3. **Add the following lines**:
   ```
   127.0.0.1  n8n-dev.local
   127.0.0.1  n8n-uat.local
   ```

4. **Save the file** (you may need to save as "All Files" type)

5. **Flush DNS cache**:
   ```powershell
   ipconfig /flushdns
   ```

6. **Test access**: `http://n8n-dev.local`
   - ⚠️ If this times out, port 80 is not accessible (Docker Desktop limitation)
   - ✅ Use Option 2 (Port-Forward) instead - it works reliably

---

### Option 2: Use kubectl Port-Forward (Quick Access) ⭐ **RECOMMENDED FOR DOCKER DESKTOP**

This bypasses ingress and directly forwards the service port. **This is the most reliable method for Docker Desktop and works immediately without any configuration:**

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

**Pro Tip**: You can run multiple port-forwards in separate terminal windows for different environments.

**Helper Script**: A helper script `start-n8n-port-forwards.ps1` is available in the repository root to start all port-forwards automatically.

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

### Can't Access After Adding to Hosts File (Docker Desktop Issue)

**Common Issue**: On Docker Desktop, `http://n8n-dev.local` times out even with correct hosts file configuration.

**Root Cause**: Port 80 is not accessible on Docker Desktop, which prevents ingress from working.

**Solution**: Use port-forwarding instead (Option 2). It's more reliable and works immediately:

```powershell
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
# Then access: http://localhost:5678
```

**If you still want to troubleshoot ingress**:

1. **Verify hosts file syntax**:
   - No extra spaces
   - IP address first, then hostname
   - One entry per line
   - Should use `127.0.0.1` not `192.168.x.x`

2. **Check if DNS resolves**:
   ```powershell
   ping n8n-dev.local
   # Should resolve to 127.0.0.1
   ```

3. **Check if port 80 is accessible**:
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 80
   # If this fails, port 80 is not accessible (Docker Desktop limitation)
   ```

4. **Check Windows Firewall**:
   - May be blocking connections
   - Temporarily disable to test

5. **Verify ingress controller is running**:
   ```powershell
   kubectl get pods -n ingress-nginx
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```

---

## Quick Reference Commands (Local PC)

```powershell
# ⭐ Port forward (easiest for local PC - RECOMMENDED)
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

