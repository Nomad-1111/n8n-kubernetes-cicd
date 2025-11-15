# Outstanding Issues and Tasks

**Last Updated**: November 2025  
**Status**: Active tracking of remaining work

---

## 🔴 Critical / High Priority

### 1. Docker Hub Secrets Configuration (BLOCKING CI/CD)

**Status**: ⚠️ **REQUIRED FOR WORKFLOW TO RUN**  
**Priority**: CRITICAL  
**Impact**: GitHub Actions workflow cannot build/push images without this

**Description**:
- GitHub Actions workflow is configured and ready
- Requires Docker Hub credentials to push images
- Without secrets, workflow will fail on Docker Hub login

**Action Required**:
1. Go to GitHub repository: Settings → Secrets and variables → Actions
2. Add new repository secret: `DOCKER_USERNAME` = `nomad1111`
3. Add new repository secret: `DOCKER_PASSWORD` = Your Docker Hub access token
4. Test workflow by pushing to `develop` branch

**Reference**: See `CI_CD_PROCESS.md` for detailed instructions

---

### 2. Switch UAT/Prod to Custom Images

**Status**: ⚠️ **PENDING IMAGE BUILD**  
**Priority**: HIGH  
**Impact**: Currently using official `n8nio/n8n:latest` temporarily

**Description**:
- UAT and prod values files have TODO comments
- Currently using `n8nio/n8n:latest` as temporary solution
- Need to switch to `nomad1111/n8n-custom:uat` and `nomad1111/n8n-custom:main`

**Action Required**:
1. Once Docker Hub secrets are configured, push to `uat` or `main` branch
2. GitHub Actions will automatically:
   - Build custom image
   - Push to Docker Hub
   - Update Helm values files
   - Remove TODO comments
3. Argo CD will auto-sync and deploy custom images

**Current State**:
- `helm/values-uat.yaml`: Using `n8nio/n8n:latest` (temporary)
- `helm/values-prod.yaml`: Using `n8nio/n8n:latest` (temporary)

---

### 3. Port-Forward Timeout for UAT/Prod

**Status**: ✅ **RESOLVED**  
**Priority**: ~~MEDIUM~~ (COMPLETED)  
**Impact**: ~~Cannot access UAT/prod via port-forward~~ → **All environments now accessible**

**Resolution**:
- Root cause: Pod labels didn't include required Kubernetes standard labels
- Fix: Updated pod labels to include:
  - `app.kubernetes.io/name: n8n`
  - `app.kubernetes.io/instance: n8n-<env>`
  - `app.kubernetes.io/part-of: n8n`
- Service endpoints now properly populated
- Port-forwarding works for all three environments

**Current Access**:
```powershell
# Dev
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
# Access: http://localhost:5678

# UAT
kubectl port-forward -n n8n-uat svc/workflow-api-svc 5679:5678
# Access: http://localhost:5679

# Prod
kubectl port-forward -n n8n-prod svc/workflow-api-svc 5680:5678
# Access: http://localhost:5680
```

**Note**: See `ACCESS_N8N.md` for detailed troubleshooting if issues occur

---

## 🟡 Medium Priority

### 4. Production Domain Configuration

**Status**: ⚠️ **PLACEHOLDER VALUE**  
**Priority**: MEDIUM  
**Impact**: Production ingress won't work with placeholder domain

**Description**:
- `helm/values-prod.yaml` has placeholder: `host: n8n.yourdomain.com`
- Needs to be updated with actual production domain
- TLS certificates need to be configured

**Action Required**:
1. Update `helm/values-prod.yaml`:
   ```yaml
   ingress:
     host: n8n.your-actual-domain.com
     protocol: https
   ```
2. Configure TLS certificates (Let's Encrypt, cert-manager, etc.)
3. Update TLS section in ingress configuration
4. Commit and push to `main` branch

---

### 5. Docker Hub Authentication (Rate Limiting)

**Status**: ℹ️ **OPTIONAL BUT RECOMMENDED**  
**Priority**: MEDIUM  
**Impact**: May hit Docker Hub rate limits for anonymous pulls

**Description**:
- Docker Hub has rate limits for anonymous image pulls
- May cause `ImagePullBackOff` errors under high load
- Can be mitigated with Docker Hub authentication

**Action Required**:
1. Create Docker Hub account (if not already)
2. Create imagePullSecret:
   ```bash
   kubectl create secret docker-registry dockerhub-secret \
     --docker-server=https://index.docker.io/v1/ \
     --docker-username=<username> \
     --docker-password=<password> \
     --docker-email=<email> \
     -n <namespace>
   ```
3. Update values files: `pullSecrets: ["dockerhub-secret"]`
4. Apply to all three environments

**Reference**: See `DEPLOYMENT_FIXES_SUMMARY.md` for details

---

### 6. Argo CD Sync Status

**Status**: ⚠️ **UAT/PROD OUT OF SYNC**  
**Priority**: MEDIUM  
**Impact**: Manual intervention may be needed for deployments

**Description**:
- Dev environment: Synced and Healthy ✅
- UAT environment: OutOfSync, Degraded ⚠️
- Prod environment: OutOfSync, Degraded ⚠️

**Action Required**:
1. Check Argo CD application status: `kubectl get applications -n argocd`
2. Review sync differences: Check Argo CD UI or use CLI
3. Force sync if needed (though auto-sync should handle it)
4. Verify all resources are properly labeled for Helm management

---

## 🟢 Low Priority / Future Enhancements

### 7. Resource Limits & Requests

**Status**: 📋 **NOT CONFIGURED**  
**Priority**: LOW  
**Impact**: No resource guarantees, potential OOM kills

**Description**:
- Deployments don't specify resource requests or limits
- Could lead to resource contention or unexpected behavior

**Recommendation**:
- Add to deployment template:
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

### 8. Health Checks (Liveness/Readiness Probes)

**Status**: 📋 **NOT CONFIGURED**  
**Priority**: LOW  
**Impact**: Kubernetes can't detect unhealthy pods automatically

**Description**:
- No liveness or readiness probes configured
- Kubernetes can't automatically restart unhealthy pods
- No graceful shutdown handling

**Recommendation**:
- Add to deployment template:
  ```yaml
  livenessProbe:
    httpGet:
      path: /healthz
      port: 5678
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /healthz
      port: 5678
    initialDelaySeconds: 10
    periodSeconds: 5
  ```

---

### 9. ConfigMaps for Environment-Specific Config

**Status**: 📋 **NOT IMPLEMENTED**  
**Priority**: LOW  
**Impact**: Less flexible configuration management

**Description**:
- Environment variables are hardcoded in deployment template
- Difficult to update without redeploying

**Recommendation**:
- Create ConfigMaps for environment-specific settings
- Reference ConfigMaps in deployment
- Allows easier configuration updates

---

### 10. Database Migration (Production)

**Status**: 📋 **FUTURE ENHANCEMENT**  
**Priority**: LOW  
**Impact**: SQLite doesn't scale well for production

**Description**:
- Currently using SQLite for all environments
- SQLite has limitations for production workloads
- No high availability or backup capabilities

**Recommendation**:
- Migrate to PostgreSQL or MySQL for production
- Use managed database service (RDS, Cloud SQL, etc.)
- Update DB_TYPE and connection strings in values files
- Keep SQLite for dev/uat if desired

---

### 11. Monitoring and Alerting

**Status**: 📋 **NOT CONFIGURED**  
**Priority**: LOW  
**Impact**: No visibility into application health and performance

**Description**:
- No monitoring solution configured
- No alerting for failures or performance issues
- No metrics collection

**Recommendation**:
- Set up Prometheus and Grafana
- Configure n8n metrics endpoints
- Set up alerts for pod failures, high CPU/memory, etc.
- Consider using managed monitoring solutions

---

### 12. Backup and Disaster Recovery

**Status**: 📋 **NOT CONFIGURED**  
**Priority**: LOW  
**Impact**: Risk of data loss

**Description**:
- No backup strategy for n8n data
- PVCs contain workflow data and credentials
- No disaster recovery plan

**Recommendation**:
- Set up regular backups of PVCs
- Use Velero or similar backup tool
- Test restore procedures
- Document backup and recovery process

---

## ✅ Completed Items

1. ✅ Fixed ServiceAccount template mismatches
2. ✅ Added template conditionals for resource creation
3. ✅ Fixed missing timezone and replicas in UAT/Prod
4. ✅ Fixed Argo CD branch configuration
5. ✅ Fixed storageClass empty string issue
6. ✅ Added standard labels to all resources
7. ✅ Fixed n8n "Command not found" error
8. ✅ Fixed image pull failures
9. ✅ Fixed n8n public URL configuration
10. ✅ Updated to use custom Docker Hub repository
11. ✅ Created GitHub Actions CI/CD workflow
12. ✅ Created comprehensive documentation
13. ✅ Got all three environments (dev/uat/prod) running
14. ✅ Created access guide for local PC deployment
15. ✅ Fixed port-forward timeout for UAT/prod environments

---

## 📊 Summary

| Priority | Count | Status |
|----------|-------|--------|
| Critical | 1 | ⚠️ Requires action |
| High | 2 | ⚠️ In progress |
| Medium | 2 | ⚠️ Needs attention |
| Low | 6 | 📋 Future work |
| Completed | 15 | ✅ Done |

---

## 🎯 Immediate Action Items

1. **Add Docker Hub secrets to GitHub** (CRITICAL - blocks CI/CD)
2. **Test GitHub Actions workflow** (push to develop branch)
3. **Verify custom images are built and pushed**
4. **Switch UAT/prod to custom images** (automatic via workflow)
5. **Update production domain** in values-prod.yaml

---

## 📚 Related Documentation

- **CI/CD Process**: `CI_CD_PROCESS.md`
- **Deployment Fixes**: `DEPLOYMENT_FIXES_SUMMARY.md`
- **Access Guide**: `ACCESS_N8N.md`
- **Main README**: `README.md`

---

*This document should be updated as issues are resolved and new ones are identified.*

