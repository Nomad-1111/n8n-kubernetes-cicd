# How to Access n8n (Local PC Deployment)

## Problem

When trying to access `n8n-dev.local`, you get:
```
DNS_PROBE_FINISHED_NXDOMAIN
This site can't be reached
```

This is because `.local` domains are not automatically resolved by DNS. Since you're deploying on your local PC, you need to configure your system to resolve them.

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

### Option 1: Add to Windows Hosts File (Recommended for Local Development)

1. **Open Notepad as Administrator**:
   - Press `Win + X`
   - Select "Windows Terminal (Admin)" or "Command Prompt (Admin)"
   - Or right-click Notepad → "Run as administrator"

2. **Open the hosts file**:
   - Navigate to: `C:\Windows\System32\drivers\etc\hosts`
   - Open with Notepad

3. **Add the following lines** (replace `<INGRESS_IP>` with your ingress controller IP):
   ```
   <INGRESS_IP>  n8n-dev.local
   <INGRESS_IP>  n8n-uat.local
   ```

4. **Find your Ingress Controller IP** (for Docker Desktop on local PC):
   
   **For Docker Desktop Kubernetes:**
   ```powershell
   # Check if ingress controller is installed
   kubectl get svc -A | findstr ingress
   
   # If not installed, install it:
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   
   # Get the ingress controller IP (usually localhost or 127.0.0.1 for Docker Desktop)
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```
   
   **For Docker Desktop, the IP is usually:**
   - `127.0.0.1` or `localhost` (if using NodePort)
   - Check the EXTERNAL-IP column in the service output
   
   **Alternative - Use localhost directly:**
   ```
   127.0.0.1  n8n-dev.local
   127.0.0.1  n8n-uat.local
   ```

5. **Save the file** (you may need to save as "All Files" type)

6. **Flush DNS cache**:
   ```powershell
   ipconfig /flushdns
   ```

7. **Access n8n**: `http://n8n-dev.local`

---

### Option 2: Use kubectl Port-Forward (Quick Access) ⭐ RECOMMENDED FOR LOCAL PC

This bypasses ingress and directly forwards the service port. **This is the easiest method for local development:**

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

### Can't Access After Adding to Hosts File

1. **Verify hosts file syntax**:
   - No extra spaces
   - IP address first, then hostname
   - One entry per line

2. **Check if IP is correct**:
   ```powershell
   ping n8n-dev.local
   # Should resolve to the IP you added
   ```

3. **Try accessing with IP directly**:
   ```powershell
   curl -H "Host: n8n-dev.local" http://<INGRESS_IP>
   ```

4. **Check Windows Firewall**:
   - May be blocking connections
   - Temporarily disable to test

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
**Use Option 1 (Hosts File)** + Ingress:
1. Install ingress controller (if not already installed)
2. Add entries to hosts file pointing to `127.0.0.1`
3. Access via `http://n8n-dev.local`

### Why Port-Forward is Better for Local PC:
- ✅ No need to install/configure ingress controller
- ✅ No need to modify hosts file
- ✅ Works immediately
- ✅ No DNS issues
- ✅ Can run multiple environments on different ports

### When to Use Ingress on Local PC:
- Testing ingress configuration before production
- Testing TLS/SSL certificates
- Testing domain-based routing
- Multiple services that need proper routing

---

*Last Updated: November 2025*

