# ============================================================================
# Trust Self-Signed Certificates for n8n
# ============================================================================
# This script exports and installs self-signed certificates to Windows
# certificate store so browsers trust them (no security warnings).
# 
# IMPORTANT: Must be run as Administrator
# ============================================================================

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "Then run: .\scripts\trust-certificates.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Trusting n8n Self-Signed Certificates" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$environments = @("dev", "uat", "prod")
$certPath = $PWD
$successCount = 0
$skipCount = 0

foreach ($env in $environments) {
    Write-Host "Processing n8n-$env..." -ForegroundColor Yellow
    
    # Check if certificate secret exists
    kubectl get secret "n8n-$env-tls" -n "n8n-$env" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Certificate not found (may not be created yet)" -ForegroundColor Yellow
        $skipCount++
        continue
    }
    
    # Export certificate
    $certData = kubectl get secret "n8n-$env-tls" -n "n8n-$env" -o jsonpath='{.data.tls\.crt}' 2>&1
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($certData)) {
        Write-Host "  Failed to export certificate" -ForegroundColor Yellow
        $skipCount++
        continue
    }
    
    try {
        # Decode base64 certificate
        $certContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($certData))
        $certFile = Join-Path $certPath "n8n-$env.crt"
        $certContent | Out-File -Encoding ASCII $certFile
        
        # Import to Windows certificate store (Trusted Root Certification Authorities)
        Import-Certificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop | Out-Null
        
        Write-Host "  Certificate trusted successfully" -ForegroundColor Green
        $successCount++
        
        # Clean up certificate file
        Remove-Item $certFile -ErrorAction SilentlyContinue
        
    } catch {
        # Check if certificate already exists
        if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*duplicate*") {
            Write-Host "  Certificate already trusted" -ForegroundColor Cyan
            $successCount++
        } else {
            Write-Host "  Failed to import certificate: $($_.Exception.Message)" -ForegroundColor Red
            $skipCount++
        }
        
        # Clean up certificate file if it exists
        Remove-Item $certFile -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Certificate Trust Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Trusted: $successCount certificate(s)" -ForegroundColor Green
if ($skipCount -gt 0) {
    Write-Host "  Skipped: $skipCount certificate(s)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart your browser completely (close all windows)" -ForegroundColor White
Write-Host "2. Access your n8n instances:" -ForegroundColor White
Write-Host "   - Dev:  https://n8n-dev.local" -ForegroundColor Gray
Write-Host "   - UAT:  https://n8n-uat.local" -ForegroundColor Gray
Write-Host "   - Prod: https://n8n-prod.local" -ForegroundColor Gray
Write-Host "3. You should no longer see security warnings!" -ForegroundColor White

Write-Host ""
Write-Host "Note: If warnings still appear, try:" -ForegroundColor Yellow
Write-Host "  - Clear browser cache" -ForegroundColor Gray
Write-Host "  - Use incognito/private mode to test" -ForegroundColor Gray
Write-Host "  - Verify certificate is installed" -ForegroundColor Gray
