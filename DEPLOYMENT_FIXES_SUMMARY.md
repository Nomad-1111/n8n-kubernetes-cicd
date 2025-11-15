# n8n Deployment Fixes - Summary Document

## Overview

This document summarizes all the fixes and improvements made to the n8n Helm chart and Argo CD deployment configuration to resolve deployment issues and improve the overall setup.

**Date**: November 2025  
**Repository**: https://github.com/Nomad-1111/n8n.git  
**Docker Hub Repository**: https://hub.docker.com/repository/docker/nomad1111/n8n-custom

---

## Issues Fixed

### 1. ServiceAccount Template Mismatch (CRITICAL - BLOCKING)

**Problem**: 
- `serviceaccount.yaml` template was using `.Values.serviceAccountName`
- `deployment.yaml` was using `.Values.serviceAccount.name`
- This inconsistency caused template rendering failures

**Solution**:
- Updated `serviceaccount.yaml` to use `.Values.serviceAccount.name` consistently
- Added conditional `{{- if .Values.serviceAccount.create }}` to only create when enabled
- Added namespace metadata using `{{ .Release.Namespace }}`
- Standardized all values files to use consistent `serviceAccount` structure
- Removed redundant `serviceAccountName` field from UAT/Prod values

**Files Modified**:
- `helm/templates/serviceaccount.yaml`
- `helm/templates/deployment.yaml`
- `helm/values-uat.yaml`
- `helm/values-prod.yaml`

---

### 2. Missing Template Conditionals

**Problem**:
- ServiceAccount and PVC templates always created resources regardless of enabled flags
- Could cause conflicts when resources should be disabled

**Solution**:
- Wrapped PVC template with `{{- if .Values.persistence.enabled }}`
- Added conditional for ServiceAccount creation
- Added conditional for storageClass rendering (only if not null)

**Files Modified**:
- `helm/templates/serviceaccount.yaml`
- `helm/templates/pvc.yaml`
- `helm/templates/deployment.yaml`

---

### 3. Missing Required Values

**Problem**:
- UAT and Prod values files were missing root-level `timezone` and `replicas`
- These values were only in an unused `pods` section
- Deployment template would fail when rendering `{{ .Values.timezone }}`

**Solution**:
- Added `timezone: Australia/Sydney` to root level in UAT/Prod values
- Added `replicas` to root level (1 for UAT, 2 for Prod)
- Removed unused `pods` section from both files

**Files Modified**:
- `helm/values-uat.yaml`
- `helm/values-prod.yaml`

---

### 4. Argo CD Branch Configuration

**Problem**:
- UAT Argo CD application was watching `develop` branch instead of `uat`
- UAT environment was not properly isolated

**Solution**:
- Updated `argo/n8n-uat.yaml` to watch `uat` branch
- Now properly aligned: dev → develop, uat → uat, prod → main

**Files Modified**:
- `argo/n8n-uat.yaml`

---

### 5. StorageClass Configuration

**Problem**:
- Empty string `storageClass: ""` could cause Kubernetes issues
- PVC creation might fail with invalid storageClass value

**Solution**:
- Changed `storageClass: ""` to `storageClass: null` in all values files
- Added conditional rendering in PVC template to only include storageClassName if not null

**Files Modified**:
- `helm/values-dev.yaml`
- `helm/values-uat.yaml`
- `helm/values-prod.yaml`
- `helm/templates/pvc.yaml`

---

### 6. Resource Labels

**Problem**:
- Resources lacked standard Kubernetes labels
- Made resource management and filtering difficult

**Solution**:
- Applied standard labels from `_helpers.tpl` to all resources:
  - ServiceAccount
  - PVC
  - Deployment
  - Service
  - Ingress

**Files Modified**:
- `helm/templates/serviceaccount.yaml`
- `helm/templates/pvc.yaml`
- `helm/templates/deployment.yaml`
- `helm/templates/service.yaml`
- `helm/templates/ingress.yaml`

---

### 7. n8n "Command not found" Error

**Problem**:
- Pods were failing with error: `Error: Command "n8n" not found`
- Custom image `nomad1111/n8n-custom:develop` either didn't exist or wasn't built correctly

**Solution**:
- Initially switched to official `n8nio/n8n:latest` image as temporary fix
- Later updated to use custom repository `nomad1111/n8n-custom` with proper tags
- Added optional command/args support in deployment template
- Changed pullPolicy to `Always` to ensure latest images are pulled

**Files Modified**:
- `helm/templates/deployment.yaml`
- `helm/values-dev.yaml`
- `helm/values-uat.yaml`
- `helm/values-prod.yaml`

---

### 8. Image Pull Failure

**Problem**:
- Container was "trying and failing to pull image"
- Image tag `develop` didn't exist for the n8n image

**Solution**:
- Fixed image tag from `develop` to `latest` (then back to branch-based tags)
- Changed pullPolicy from `IfNotPresent` to `Always`
- Added support for `imagePullSecrets` in deployment template for Docker Hub authentication

**Files Modified**:
- `helm/templates/deployment.yaml`
- `helm/values-dev.yaml`
- `helm/values-uat.yaml`
- `helm/values-prod.yaml`

---

### 9. n8n Public URL Configuration

**Problem**:
- n8n was displaying `@http://0.0.0.0:5678` instead of proper public URL
- Webhooks and OAuth callbacks would fail due to incorrect URL

**Solution**:
- Added `N8N_PROTOCOL` environment variable (http/https based on ingress)
- Added `WEBHOOK_URL` environment variable with full public URL
- Configured protocol in all values files:
  - Dev: `http`
  - UAT: `http`
  - Prod: `https`

**Files Modified**:
- `helm/templates/deployment.yaml`
- `helm/values-dev.yaml`
- `helm/values-uat.yaml`
- `helm/values-prod.yaml`

---

### 10. Custom Docker Hub Repository Configuration

**Problem**:
- Configuration was using official `n8nio/n8n` image instead of custom repository

**Solution**:
- Updated all values files to use `nomad1111/n8n-custom` repository
- Configured branch-based tags:
  - Dev: `nomad1111/n8n-custom:develop`
  - UAT: `nomad1111/n8n-custom:uat`
  - Prod: `nomad1111/n8n-custom:main`

**Files Modified**:
- `helm/values-dev.yaml`
- `helm/values-uat.yaml`
- `helm/values-prod.yaml`

---

## Current Configuration

### Image Configuration

| Environment | Repository | Tag | Pull Policy |
|------------|------------|-----|-------------|
| Dev | `nomad1111/n8n-custom` | `develop` | `Always` |
| UAT | `nomad1111/n8n-custom` | `uat` | `Always` |
| Prod | `nomad1111/n8n-custom` | `main` | `Always` |

### Environment Variables

All environments now have:
- `N8N_PORT`: 5678
- `N8N_HOST`: 0.0.0.0
- `N8N_PROTOCOL`: http (dev/uat) or https (prod)
- `WEBHOOK_URL`: Full public URL based on ingress host
- `GENERIC_TIMEZONE`: Australia/Sydney
- `DB_TYPE`: sqlite
- `DB_SQLITE_VACUUM_ON_STARTUP`: true

### Ingress Configuration

| Environment | Host | Protocol |
|------------|------|----------|
| Dev | `n8n-dev.local` | http |
| UAT | `n8n-uat.local` | http |
| Prod | `n8n.yourdomain.com` | https |

### Storage Configuration

| Environment | Size | Access Mode |
|------------|------|-------------|
| Dev | 1Gi | ReadWriteOnce |
| UAT | 1Gi | ReadWriteOnce |
| Prod | 5Gi | ReadWriteOnce |

### Replicas

| Environment | Replicas |
|------------|----------|
| Dev | 1 |
| UAT | 1 |
| Prod | 2 |

---

## Outstanding Issues & Recommendations

### 1. GitHub Actions Workflows ✅ COMPLETED

**Status**: Implemented  
**Impact**: Automated CI/CD pipeline now active

**Description**:
- GitHub Actions workflow (`.github/workflows/ci-cd.yaml`) has been created and configured
- Automatically builds Docker images on push to `develop`, `uat`, or `main` branches
- Pushes images to Docker Hub as `nomad1111/n8n-custom:<branch-name>`
- Updates Helm values files automatically
- Commits changes back to repository
- Argo CD auto-syncs deployments

**Setup Required**:
- Add Docker Hub secrets to GitHub repository:
  - `DOCKER_USERNAME` = `nomad1111`
  - `DOCKER_PASSWORD` = Docker Hub access token
- See `CI_CD_PROCESS.md` for detailed setup instructions

**Status**: Workflow is ready, awaiting Docker Hub credentials

---

### 2. Hardcoded Credentials (MEDIUM PRIORITY)

**Status**: Present in values files  
**Impact**: Security risk

**Description**:
- Basic auth credentials are hardcoded in values files (if they exist)
- Should use Kubernetes Secrets instead

**Recommendation**:
- Create Kubernetes Secrets for sensitive data
- Reference secrets in deployment template
- Remove hardcoded credentials from values files
- Use Sealed Secrets or External Secrets Operator for GitOps-friendly secret management

---

### 3. Docker Hub Authentication (MEDIUM PRIORITY)

**Status**: Optional but recommended  
**Impact**: Rate limiting issues

**Description**:
- Docker Hub has rate limits for anonymous pulls
- May cause image pull failures under high load

**Recommendation**:
- Create Docker Hub account (free tier available)
- Create imagePullSecret:
  ```bash
  kubectl create secret docker-registry dockerhub-secret \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=<username> \
    --docker-password=<password> \
    --docker-email=<email> \
    -n <namespace>
  ```
- Add to values files: `pullSecrets: ["dockerhub-secret"]`

---

### 4. Production Domain Configuration (MEDIUM PRIORITY)

**Status**: Placeholder value  
**Impact**: Production ingress won't work correctly

**Description**:
- `values-prod.yaml` has placeholder: `host: n8n.yourdomain.com`
- Needs to be updated with actual production domain

**Recommendation**:
- Update `helm/values-prod.yaml` with actual production domain
- Configure TLS certificates (Let's Encrypt, cert-manager, etc.)
- Update `protocol: https` and configure TLS section in ingress

---

### 5. Resource Limits & Requests (LOW PRIORITY)

**Status**: Not configured  
**Impact**: No resource guarantees or limits

**Description**:
- Deployments don't specify resource requests or limits
- Could lead to resource contention or OOM kills

**Recommendation**:
- Add resource requests and limits to deployment template
- Configure based on n8n requirements:
  ```yaml
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  ```

---

### 6. ConfigMaps for Environment-Specific Config (LOW PRIORITY)

**Status**: Not implemented  
**Impact**: Less flexible configuration management

**Description**:
- Environment variables are hardcoded in deployment template
- Difficult to manage environment-specific configurations

**Recommendation**:
- Create ConfigMaps for environment-specific settings
- Reference ConfigMaps in deployment
- Allows easier configuration updates without redeploying

---

### 7. Health Checks (LOW PRIORITY)

**Status**: Not configured  
**Impact**: Kubernetes can't detect unhealthy pods

**Description**:
- No liveness or readiness probes configured
- Kubernetes can't automatically restart unhealthy pods

**Recommendation**:
- Add liveness probe: `/healthz` endpoint
- Add readiness probe: `/healthz` endpoint
- Configure appropriate timeouts and thresholds

---

### 8. Database Configuration (FUTURE)

**Status**: Using SQLite  
**Impact**: Limited scalability

**Description**:
- Currently using SQLite for all environments
- SQLite doesn't scale well for production workloads

**Recommendation**:
- Consider PostgreSQL or MySQL for production
- Use managed database service (RDS, Cloud SQL, etc.)
- Update DB_TYPE and connection strings in values files

---

## Git Commits Summary

1. **eb27249** - Fix n8n Argo CD deployment issues (ServiceAccount, conditionals, missing values)
2. **5599ca6** - Fix n8n 'Command not found' error by using official image
3. **7292068** - Fix n8n public URL configuration (WEBHOOK_URL, N8N_PROTOCOL)
4. **8d25699** - Fix image pull failure - correct image tag and add pullSecrets support
5. **d049615** - Update to use custom Docker Hub repository nomad1111/n8n-custom
6. **671295e** - Temporarily use official n8n image for UAT and prod
7. **f47071a** - Automate custom image build and deployment process
8. **12e5a91** - Add n8n access guide for local PC deployment
9. **b777e4c** - Add comprehensive deployment fixes summary document

---

## Testing & Validation

### Helm Template Validation

All templates have been validated using:
```bash
helm template test-dev . -f values-dev.yaml
helm template test-uat . -f values-uat.yaml
helm template test-prod . -f values-prod.yaml
```

### Argo CD Sync Status

After fixes, Argo CD should:
- Successfully sync all three environments
- Deploy pods without errors
- Pull images from Docker Hub successfully
- Configure n8n with correct public URLs

---

## Next Steps

1. **Immediate** (REQUIRED):
   - ✅ CI/CD workflow created and configured
   - ⚠️ **Add Docker Hub secrets to GitHub** (DOCKER_USERNAME, DOCKER_PASSWORD)
   - Test workflow by pushing to develop/uat/main branch
   - Verify images are built and pushed to Docker Hub
   - Switch UAT/prod from official image to custom images once built

2. **Short-term**:
   - Update production domain configuration (currently placeholder)
   - Set up Docker Hub authentication (imagePullSecrets) if rate limiting occurs
   - Test port-forwarding for UAT and prod (currently timing out)

3. **Long-term**:
   - Implement resource limits and requests
   - Add health checks (liveness/readiness probes)
   - Consider database migration for production (PostgreSQL/MySQL)
   - Set up monitoring and alerting
   - Configure TLS certificates for production ingress

---

## References

- **Repository**: https://github.com/Nomad-1111/n8n.git
- **Docker Hub**: https://hub.docker.com/repository/docker/nomad1111/n8n-custom
- **n8n Documentation**: https://docs.n8n.io/
- **Helm Documentation**: https://helm.sh/docs/

---

## Notes

- All changes have been committed and pushed to the `develop` branch
- Argo CD is configured to auto-sync with prune and self-heal enabled
- The deployment uses branch-based image tags aligned with Git branches
- Timezone is configured for Australia/Sydney across all environments

---

*Last Updated: November 2025*

