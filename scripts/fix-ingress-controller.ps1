# ============================================================================
# Fix Ingress Controller for Docker Desktop
# ============================================================================
# This script configures the NGINX ingress controller to use port 8080
# instead of port 80, which is not accessible on Docker Desktop.
# 
# After running this script, you can access n8n via:
#   - Dev:  http://n8n-dev.local:30080
#   - UAT:  http://n8n-uat.local:30080
#   - Prod: http://n8n-prod.local:30080
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Fixing Ingress Controller for Docker Desktop" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if ingress controller exists
Write-Host "Checking if ingress controller is installed..." -ForegroundColor Yellow
kubectl get svc -n ingress-nginx ingress-nginx-controller 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ ERROR: Ingress controller not found!" -ForegroundColor Red
    Write-Host "`nPlease install it first using:" -ForegroundColor Yellow
    Write-Host "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml" -ForegroundColor White
    Write-Host "`nOr see SETUP_GUIDE.md Step 5 for detailed instructions." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Ingress controller found" -ForegroundColor Green

# Check current service configuration
Write-Host "`nChecking current ingress controller configuration..." -ForegroundColor Yellow
$currentSvc = kubectl get svc -n ingress-nginx ingress-nginx-controller -o json | ConvertFrom-Json
Write-Host "  Current type: $($currentSvc.spec.type)" -ForegroundColor Gray
if ($currentSvc.spec.ports) {
    foreach ($port in $currentSvc.spec.ports) {
        Write-Host "  Port $($port.port) -> $($port.targetPort) (NodePort: $($port.nodePort))" -ForegroundColor Gray
    }
}

# Patch the service to use NodePort on port 30080
Write-Host "`nPatching ingress controller service to use NodePort on port 30080..." -ForegroundColor Yellow

# Create patch JSON
$patchJson = @"
[
  {
    "op": "replace",
    "path": "/spec/type",
    "value": "NodePort"
  },
  {
    "op": "replace",
    "path": "/spec/ports/0/nodePort",
    "value": 30080
  },
  {
    "op": "replace",
    "path": "/spec/ports/1/nodePort",
    "value": 30443
  }
]
"@

# Apply the patch
$patchJson | kubectl patch svc ingress-nginx-controller -n ingress-nginx --type='json' -p=@- 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ingress controller patched successfully!" -ForegroundColor Green
    
    # Wait a moment for changes to propagate
    Start-Sleep -Seconds 2
    
    # Verify the patch
    Write-Host "`nVerifying configuration..." -ForegroundColor Yellow
    $updatedSvc = kubectl get svc -n ingress-nginx ingress-nginx-controller -o json | ConvertFrom-Json
    Write-Host "  New type: $($updatedSvc.spec.type)" -ForegroundColor Gray
    if ($updatedSvc.spec.ports) {
        foreach ($port in $updatedSvc.spec.ports) {
            Write-Host "  Port $($port.port) -> $($port.targetPort) (NodePort: $($port.nodePort))" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "✅ Setup Complete!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    Write-Host "Access your n8n instances via:" -ForegroundColor Cyan
    Write-Host "  Dev:  http://n8n-dev.local:30080" -ForegroundColor White
    Write-Host "  UAT:  http://n8n-uat.local:30080" -ForegroundColor White
    Write-Host "  Prod: http://n8n-prod.local:30080" -ForegroundColor White
    
    Write-Host "`n⚠️  IMPORTANT: Make sure you have these entries in your hosts file:" -ForegroundColor Yellow
    Write-Host "  127.0.0.1  n8n-dev.local" -ForegroundColor White
    Write-Host "  127.0.0.1  n8n-uat.local" -ForegroundColor White
    Write-Host "  127.0.0.1  n8n-prod.local" -ForegroundColor White
    Write-Host "`nLocation: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Gray
    Write-Host "After editing, run: ipconfig /flushdns" -ForegroundColor Gray
    
    Write-Host "`n💡 Benefits:" -ForegroundColor Cyan
    Write-Host "  ✅ Production-like setup (uses ingress, not port-forwarding)" -ForegroundColor Green
    Write-Host "  ✅ Survives PC standby/resume" -ForegroundColor Green
    Write-Host "  ✅ Clean URLs with hostnames" -ForegroundColor Green
    Write-Host "  ✅ No need to keep terminal windows open" -ForegroundColor Green
} else {
    Write-Host "`n❌ Failed to patch ingress controller" -ForegroundColor Red
    Write-Host "Please check the error messages above and try again." -ForegroundColor Yellow
    exit 1
}

