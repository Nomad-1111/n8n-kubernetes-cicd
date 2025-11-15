# Port-Forward Script for n8n Access
# Run this to access n8n via localhost

Write-Host "Starting port-forwards for n8n environments..." -ForegroundColor Cyan

# Dev environment
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'n8n Dev - Port Forward' -ForegroundColor Green; kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678" -WindowStyle Normal

Start-Sleep -Seconds 2

# UAT environment  
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'n8n UAT - Port Forward' -ForegroundColor Yellow; kubectl port-forward -n n8n-uat svc/workflow-api-svc 5679:5678" -WindowStyle Normal

Start-Sleep -Seconds 2

# Prod environment
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'n8n Prod - Port Forward' -ForegroundColor Magenta; kubectl port-forward -n n8n-prod svc/workflow-api-svc 5680:5678" -WindowStyle Normal

Write-Host "
Port-forwards started! Access:" -ForegroundColor Green
Write-Host "  Dev:  http://localhost:5678" -ForegroundColor Green
Write-Host "  UAT:  http://localhost:5679" -ForegroundColor Yellow
Write-Host "  Prod: http://localhost:5680" -ForegroundColor Magenta
Write-Host "
Press any key to stop all port-forwards..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
