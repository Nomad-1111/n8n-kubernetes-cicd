# ============================================================================
# Setup Let's Encrypt with cert-manager
# ============================================================================
# This script creates a Let's Encrypt ClusterIssuer for automatic
# certificate management. Requires real, publicly accessible domains.
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Email = "your-email@example.com",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("staging", "prod")]
    [string]$Environment = "staging"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setting up Let's Encrypt with cert-manager" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if cert-manager is installed
Write-Host "Checking if cert-manager is installed..." -ForegroundColor Yellow
kubectl get pods -n cert-manager --no-headers 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ cert-manager is not installed!" -ForegroundColor Red
    Write-Host "Please run .\scripts\setup-https.ps1 first to install cert-manager." -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ cert-manager is installed" -ForegroundColor Green

# Determine Let's Encrypt server
if ($Environment -eq "staging") {
    $server = "https://acme-staging-v02.api.letsencrypt.org/directory"
    $issuerName = "letsencrypt-staging"
    Write-Host "`nUsing Let's Encrypt STAGING environment (for testing)" -ForegroundColor Yellow
    Write-Host "⚠️  Staging certificates will show browser warnings" -ForegroundColor Yellow
} else {
    $server = "https://acme-v02.api.letsencrypt.org/directory"
    $issuerName = "letsencrypt-prod"
    Write-Host "`nUsing Let's Encrypt PRODUCTION environment" -ForegroundColor Green
    Write-Host "⚠️  Production has rate limits (50 certs/week per domain)" -ForegroundColor Yellow
}

# Prompt for email if not provided
if ($Email -eq "your-email@example.com") {
    $Email = Read-Host "Enter your email address for Let's Encrypt notifications"
    if ([string]::IsNullOrWhiteSpace($Email)) {
        Write-Host "❌ Email address is required" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nEmail: $Email" -ForegroundColor Cyan
Write-Host "Issuer name: $issuerName" -ForegroundColor Cyan

# Create ClusterIssuer
Write-Host "`nCreating Let's Encrypt ClusterIssuer..." -ForegroundColor Yellow

$issuerYaml = @"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: $issuerName
spec:
  acme:
    server: $server
    email: $Email
    privateKeySecretRef:
      name: $issuerName
    solvers:
    - http01:
        ingress:
          class: nginx
"@

$issuerYaml | kubectl apply -f - 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Let's Encrypt ClusterIssuer created" -ForegroundColor Green
} else {
    Write-Host "⚠️  ClusterIssuer may already exist (this is okay)" -ForegroundColor Yellow
}

# Verify
Write-Host "`nVerifying ClusterIssuer..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

kubectl get clusterissuer $issuerName 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ClusterIssuer '$issuerName' is ready" -ForegroundColor Green
} else {
    Write-Host "⚠️  ClusterIssuer not found. It may still be creating..." -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ Let's Encrypt Setup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update your Helm values files:" -ForegroundColor White
Write-Host "   - Change ingress.host to your real domain (e.g., n8n-dev.yourdomain.com)" -ForegroundColor Gray
Write-Host "   - Update ingress.tls.issuer.name to '$issuerName'" -ForegroundColor Gray
Write-Host "`n2. Ensure your domain points to your cluster's ingress controller" -ForegroundColor White
Write-Host "`n3. Argo CD will automatically sync and certificates will be generated" -ForegroundColor White
Write-Host "`n4. For staging, test first, then switch to production issuer" -ForegroundColor White
Write-Host "`nExample values-dev.yaml configuration:" -ForegroundColor Cyan
Write-Host @"
ingress:
  host: n8n-dev.yourdomain.com
  protocol: https
  tls:
    enabled: true
    secretName: n8n-dev-tls
    issuer:
      name: $issuerName
      kind: ClusterIssuer
"@ -ForegroundColor Gray

