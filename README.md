# Full CI/CD Pipeline for n8n with GitHub Actions, Docker, Helm, and Argo CD

This repository contains a fully automated **multi-environment CI/CD pipeline** for deploying `n8n` using:

- **Docker Desktop (Kubernetes enabled)**
- **GitHub Actions**
- **Helm + Environment Values**
- **Argo CD (auto-sync enabled)**  
- **Multi‑environment support**: `dev`, `uat`, `prod`

---

# 🚀 Architecture Overview

```
Developer Commit / PR
        │
        ▼
 GitHub Actions
   ├── Build Docker Image
   ├── Push Image
   ├── Update Helm values (tag)
   └── Commit back to repo
        │
        ▼
   Argo CD (Auto‑Sync)
   ├── Detects Helm change
   ├── Syncs Deployment
   └── Kubernetes Deploys New Image
```

---

# 🏗 Folder Structure

```
repo/
│── .github/workflows/
│     └── ci-cd.yaml          # Unified workflow for all environments
│
│── helm/
│     ├── Chart.yaml
│     ├── values-dev.yaml
│     ├── values-uat.yaml
│     ├── values-prod.yaml
│     └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           └── pvc.yaml
```

---

# ⚙ GitHub Actions (Multi‑Environment)

### **Unified CI/CD Workflow**

A single workflow (`.github/workflows/ci-cd.yaml`) handles all environments:

**Triggers**:
- **Pull Requests**: Validates code (builds, scans, validates Helm charts) - no deployment
- **Push** (after PR merge): Full deployment pipeline
  - Push to `develop` branch → Builds `nomad1111/n8n-custom:develop` → Deploys to dev
  - Push to `uat` branch → Builds `nomad1111/n8n-custom:uat` → Deploys to UAT
  - Push to `main` branch → Builds `nomad1111/n8n-custom:main` → Deploys to prod

**Workflow Steps (Pull Request - Validation Only)**:
1. Checkout PR branch code
2. Set up Docker Buildx
3. Build Docker image (validation only, not pushed)
4. Scan image with Trivy
5. Validate Helm charts (lint + template rendering)
6. Report results in PR checks

**Workflow Steps (Push - Full Deployment)**:
1. Checkout code
2. Set up Docker Buildx
3. Login to Docker Hub (requires secrets: `DOCKER_USERNAME`, `DOCKER_PASSWORD`)
4. Build Docker image from `docker/Dockerfile`
5. Scan image with Trivy
6. Validate Helm charts (lint + template rendering)
7. Tag and push to Docker Hub as `nomad1111/n8n-custom:<branch-name>`
8. Update corresponding Helm values file
9. Commit and push changes back to repository
10. Argo CD auto-syncs deployment

**Branch Promotion Flow**:
- Work on `develop` → Create PR → Validate → Merge → Deploys to dev
- Promote to UAT → Create PR from `develop` to `uat` → Validate → Merge → Deploys to UAT
- Promote to Production → Create PR from `uat` to `main` → Validate → Merge → Deploys to prod

**Setup Required**:
- Add GitHub secrets: `DOCKER_USERNAME` and `DOCKER_PASSWORD`
- See `CI_CD_PROCESS.md` for detailed setup instructions

**Current Status**:
- ✅ Workflow configured and ready
- ✅ All environments accessible via port-forward (dev/uat/prod)
- ✅ Security scanning enabled (CodeQL + Trivy)
- ✅ All environments configured to use custom Docker images
- ⚠️ Awaiting Docker Hub credentials (required for first build)

---

## 🔒 Security Scanning

This repository includes automated security scanning to detect vulnerabilities:

### CodeQL Analysis
- **Runs on**: Pull requests to `develop`, `uat`, or `main` branches
- **Scans**: JavaScript/TypeScript code, YAML configs, Helm charts
- **Results**: Available in GitHub Security tab and PR annotations
- **Workflow**: `.github/workflows/codeql-analysis.yml`

### Trivy Docker Image Scanning
- **Runs on**: Every PR and push (as part of CI/CD pipeline)
- **Scans**: Built Docker images for OS packages, dependencies, and config issues
- **Results**: Uploaded to GitHub Security tab and reported in PR checks
- **Integration**: Part of `.github/workflows/ci-cd.yaml`

### Helm Chart Validation
- **Runs on**: Every PR and push (as part of CI/CD pipeline)
- **Validates**: Helm chart syntax and template rendering
- **Results**: Reported in workflow logs and PR checks
- **Integration**: Part of `.github/workflows/ci-cd.yaml`

**Note**: Security scans are **non-blocking** - they report findings but don't prevent deployments. Review findings in the GitHub Security tab.

**See `SECURITY_SCANNING.md` for detailed documentation on security scanning.**

---

# ☸ Kubernetes Deployments via Helm

Each environment has its own Helm values file that configures the deployment:

- **`helm/values-dev.yaml`** - Development environment configuration
- **`helm/values-uat.yaml`** - UAT environment configuration  
- **`helm/values-prod.yaml`** - Production environment configuration

### Example Configuration (`helm/values-dev.yaml`)

```yaml
# Container Image Configuration
image:
  repository: nomad1111/n8n-custom
  tag: develop
  pullPolicy: Always

# Application Settings
replicas: 1
timezone: Australia/Sydney

# Ingress Configuration
ingress:
  enabled: true
  className: nginx
  host: n8n-dev.local
  protocol: http

# Service Configuration
service:
  type: ClusterIP
  port: 5678
  targetPort: 5678

# Persistent Storage
persistence:
  enabled: true
  size: 1Gi
  mountPath: /home/node/.n8n
```

**See the actual values files for complete configuration options.**

---

# 🚢 Argo CD Setup

Argo CD applications are already configured in the `argo/` directory:

- **`argo/n8n-dev.yaml`** - Development environment (watches `develop` branch)
- **`argo/n8n-uat.yaml`** - UAT environment (watches `uat` branch)
- **`argo/n8n-prod.yaml`** - Production environment (watches `main` branch)

### Apply Argo CD Applications

```bash
# Apply all Argo CD applications
kubectl apply -f argo/n8n-dev.yaml
kubectl apply -f argo/n8n-uat.yaml
kubectl apply -f argo/n8n-prod.yaml
```

Each application automatically:
- Monitors the corresponding Git branch for changes
- Syncs deployments when Helm values are updated
- Maintains desired state with prune and self-heal enabled

**See `SETUP_GUIDE.md` for complete Argo CD installation and configuration.**

---

# 🔄 How the Pipeline Works (End‑to‑End)

## Pull Request Flow (Validation)

| Step | Trigger | Action |
|------|---------|--------|
| 1 | Create PR targeting `develop`/`uat`/`main` | GitHub Actions workflow triggers |
| 2 | Docker Build | Builds image from `docker/Dockerfile` (validation only) |
| 3 | Security Scan | Scans image with Trivy for vulnerabilities |
| 4 | Helm Validation | Validates Helm charts (lint + template rendering) |
| 5 | Report Results | Results shown in PR checks |

## Push Flow (Deployment)

| Step | Trigger | Action |
|------|---------|--------|
| 1 | Merge PR / Push to branch (`develop`/`uat`/`main`) | GitHub Actions workflow triggers |
| 2 | Docker Build | Builds image from `docker/Dockerfile` |
| 3 | Security Scan | Scans image with Trivy for vulnerabilities |
| 4 | Helm Validation | Validates Helm charts (lint + template rendering) |
| 5 | Tag & Push | Tags as `nomad1111/n8n-custom:<branch-name>` and pushes to Docker Hub |
| 6 | Update Helm values | Updates corresponding `values-*.yaml` file |
| 7 | Commit changes | GitHub Actions commits updated values back to repo |
| 8 | Argo CD detects change | Auto-sync begins (prune + self-heal enabled) |
| 9 | Kubernetes deploys | New image rolls out automatically |

---

# 🧪 Test the Pipeline

### 1️⃣ Create a Pull Request

Create a feature branch and open a PR targeting `develop`:

```bash
git checkout -b feature/my-changes
# Make changes
git commit -m "feat: my changes"
git push origin feature/my-changes
# Create PR on GitHub
```

### 2️⃣ GitHub Actions will validate:

- Build Docker image (validation only)
- Scan image with Trivy
- Validate Helm charts
- Report results in PR checks

### 3️⃣ Merge PR to trigger deployment:

- Build Docker image
- Push to Docker Hub
- Update Helm values
- Commit changes back to repo

### 4️⃣ Argo CD will automatically sync:

```bash
argo app get n8n-dev
```

---

# 📦 Verify Deployment

After deployment, verify the pods are running:

```bash
# Check dev environment
kubectl get pods -n n8n-dev

# Check UAT environment
kubectl get pods -n n8n-uat

# Check production environment
kubectl get pods -n n8n-prod
```

You should see pods using the custom image:

```bash
# Check which image is deployed
kubectl get deployment -n n8n-dev n8n-api -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: nomad1111/n8n-custom:develop
```

---

# 🌐 Access n8n

### Local PC Deployment (Recommended):

**Port-Forward** (easiest method):
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

### Through Ingress (requires hosts file):

```
http://n8n-dev.local
http://n8n-uat.local
http://n8n.yourdomain.com (prod)
```

**See `ACCESS_N8N.md` for detailed access instructions and troubleshooting.**

---

# 🏁 Summary

This repository now includes:

✔ Automated build pipeline (GitHub Actions)  
✔ Branch‑based environments (develop/uat/main)  
✔ Helm-based config for each environment  
✔ Argo CD auto-sync with prune and self-heal  
✔ Dockerized n8n custom build  
✔ Full CI/CD automation  
✔ Multi-environment support (dev/uat/prod)  
✔ Comprehensive documentation  

---

# 📚 Documentation

Essential documentation for this project:

- **`SETUP_GUIDE.md`** - **START HERE** - Complete step-by-step installation guide
  - Install Docker Desktop, kubectl, Helm, Argo CD
  - Configure GitHub and Docker Hub
  - Deploy all environments

- **`CI_CD_PROCESS.md`** - CI/CD workflow and branch promotion
  - PR-based promotion workflow (develop → uat → main)
  - Automated image build and deployment
  - Troubleshooting guide

- **`ACCESS_N8N.md`** - How to access n8n
  - Port-forwarding instructions
  - Ingress configuration
  - Troubleshooting access issues

- **`SECURITY_SCANNING.md`** - Security scanning information
  - CodeQL and Trivy configuration
  - Understanding scan results
  - Security best practices

---

# ⚠️ Setup Required

**New to this project? Start here:**

1. **Read `SETUP_GUIDE.md`** - Complete step-by-step installation guide
   - Install Docker Desktop, kubectl, Helm, Argo CD
   - Configure GitHub and Docker Hub
   - Deploy all environments

2. **After setup, configure CI/CD:**
   - Add Docker Hub secrets to GitHub:
     - `DOCKER_USERNAME` = `nomad1111`
     - `DOCKER_PASSWORD` = Your Docker Hub access token
   - See `CI_CD_PROCESS.md` for detailed CI/CD instructions

---

# 📄 License

MIT License
