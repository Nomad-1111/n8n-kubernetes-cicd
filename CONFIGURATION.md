# Configuration Guide

This guide lists all hardcoded references that need to be updated before using this repository.

---

## 📁 Files That Need Configuration

```
📦 Repository
├── 🔴 .github/workflows/ci-cd.yaml          (Lines 152, 159, 184)
├── 🔴 argo/
│   ├── n8n-dev.yaml                         (Line 24)
│   ├── n8n-uat.yaml                         (Line 23)
│   └── n8n-prod.yaml                        (Line 23)
├── 🔴 helm/
│   ├── values-dev.yaml                      (Line 88)
│   ├── values-uat.yaml                      (Line 80)
│   └── values-prod.yaml                     (Line 81)
└── 🟡 helm/values-prod.yaml                 (Line 105 - domain, optional)
```

🔴 = Critical (must update)  
🟡 = Optional (recommended)

---

## 🔴 Critical Configuration (Must Update)

### 1. Docker Hub Repository

**Current Placeholder**: `YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME`  
**What to Change**: Replace with your Docker Hub username/repository

**Files to Update**:

1. **`.github/workflows/ci-cd.yaml`** (Lines 152, 159, 184):
   ```yaml
   # Line 152 - Tag image
   docker tag n8n-custom:${{ steps.branch.outputs.branch }} YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME:${{ steps.branch.outputs.branch }}
   
   # Line 159 - Push image
   docker push YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME:${{ steps.branch.outputs.branch }}
   
   # Line 184 - Update Helm values
   sed -i "s|repository:.*|repository: YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME|" "$FILE"
   ```

2. **`helm/values-dev.yaml`** (Line 88):
   ```yaml
   repository: YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME
   ```

3. **`helm/values-uat.yaml`** (Line 80):
   ```yaml
   repository: YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME
   ```

4. **`helm/values-prod.yaml`** (Line 81):
   ```yaml
   repository: YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME
   ```

5. **Documentation Files** (examples - update as needed):
   - `README.md` - Multiple references
   - `CI_CD_PROCESS.md` - Multiple references
   - `SETUP_GUIDE.md` - Examples in documentation

---

### 2. GitHub Repository URL

**Current Placeholder**: `https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git`  
**What to Change**: Replace with your GitHub repository URL

**Files to Update**:

1. **`argo/n8n-dev.yaml`** (Line 24):
   ```yaml
   repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
   ```

2. **`argo/n8n-uat.yaml`** (Line 23):
   ```yaml
   repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
   ```

3. **`argo/n8n-prod.yaml`** (Line 23):
   ```yaml
   repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
   ```

4. **`SETUP_GUIDE.md`** (Lines 637, 697, 712):
   - Update git clone commands
   - Update GitHub repository URLs in examples

---

### 3. GitHub Secrets

**Current References**: Examples show placeholders  
**What to Change**: Configure your own GitHub secrets

**Action Required**:

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - **`DOCKER_USERNAME`**: Your Docker Hub username
   - **`DOCKER_PASSWORD`**: Your Docker Hub access token (not password)

**Note**: The workflow uses these secrets automatically. No code changes needed, just configure the secrets in GitHub.

**Files with Examples** (update documentation only):
- `README.md`
- `SETUP_GUIDE.md`
- `CI_CD_PROCESS.md`

---

## 🟡 Optional Configuration

### 4. Timezone

**Current Value**: `Australia/Sydney`  
**What to Change**: Update to your preferred timezone (optional)

**Files to Update**:

1. **`helm/values-dev.yaml`** (Line 32):
   ```yaml
   timezone: Your/Timezone
   # Examples: America/New_York, Europe/London, UTC
   ```

2. **`helm/values-uat.yaml`** (Line 22):
   ```yaml
   timezone: Your/Timezone
   ```

3. **`helm/values-prod.yaml`** (Line 21):
   ```yaml
   timezone: Your/Timezone
   ```

4. **`compose/docker-compose.yml`** (Line 8):
   ```yaml
   - GENERIC_TIMEZONE=Your/Timezone
   ```

---

### 5. Production Domain

**Current Value**: `n8n.yourdomain.com` (placeholder)  
**What to Change**: Update to your actual production domain

**Files to Update**:

1. **`helm/values-prod.yaml`** (Line 105):
   ```yaml
   host: n8n.yourdomain.com    # <--- UPDATE THIS with your real domain
   # Change to: host: n8n.yourcompany.com
   ```

---

## 📝 Configuration Checklist

Before deploying, ensure you've updated:

- [ ] Docker Hub repository name in CI/CD workflow (`.github/workflows/ci-cd.yaml`)
- [ ] Docker Hub repository name in all Helm values files (`helm/values-*.yaml`)
- [ ] GitHub repository URL in all Argo CD application files (`argo/n8n-*.yaml`)
- [ ] GitHub repository URL in documentation (`SETUP_GUIDE.md`)
- [ ] GitHub secrets configured (`DOCKER_USERNAME`, `DOCKER_PASSWORD`)
- [ ] Timezone settings (optional, in `helm/values-*.yaml` and `compose/docker-compose.yml`)
- [ ] Production domain name (`helm/values-prod.yaml`)

---

## 🔍 How to Find All References

Use these commands to find all hardcoded references:

```bash
# Find Docker Hub repository references
grep -r "YOUR-DOCKERHUB-USERNAME" .

# Find GitHub repository references
grep -r "YOUR-USERNAME" .

# Find timezone references
grep -r "Australia/Sydney" .
```

---

## 📚 Additional Notes

- **Service Account Names**: `n8n-dev-sa`, `n8n-uat-sa`, `n8n-prod-sa` - These are environment-specific and can be changed if needed
- **Namespace Names**: `n8n-dev`, `n8n-uat`, `n8n-prod` - These are environment-specific and can be changed if needed
- **Argo CD Namespace**: `argocd` - This is standard and typically doesn't need to change
- **Branch Names**: `develop`, `uat`, `main` - **All three branches are pre-created in the repository**. These can be changed, but you'll need to:
  - Update `.github/workflows/ci-cd.yaml` (workflow branch triggers)
  - Update `argo/n8n-dev.yaml`, `argo/n8n-uat.yaml`, `argo/n8n-prod.yaml` (targetRevision)
  - Create the new branches if they don't exist

---

## 🚀 Quick Configuration Script

You can use this script to quickly replace placeholders (adjust as needed):

```bash
#!/bin/bash

# Set your values
DOCKERHUB_USERNAME="your-dockerhub-username"
DOCKERHUB_REPO="your-repo-name"
GITHUB_USERNAME="your-github-username"
GITHUB_REPO="your-repo-name"

# Replace Docker Hub references
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" \) \
  -exec sed -i "s/YOUR-DOCKERHUB-USERNAME\/YOUR-REPO-NAME/$DOCKERHUB_USERNAME\/$DOCKERHUB_REPO/g" {} +

# Replace GitHub references
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" \) \
  -exec sed -i "s/YOUR-USERNAME\/YOUR-REPO-NAME/$GITHUB_USERNAME\/$GITHUB_REPO/g" {} +
```

**Note**: Always review changes before committing!

