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
│     ├── ci-dev.yaml
│     ├── ci-uat.yaml
│     ├── ci-prod.yaml
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

### 🧪 **ci-dev.yaml**

```yaml
name: CI/CD Dev

on:
  push:
    branches:
      - develop

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build image
        run: |
          docker build -t n8n-custom:${{ github.sha }} ./compose

      - name: Push image
        run: |
          docker tag n8n-custom:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/n8n-custom:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USERNAME }}/n8n-custom:${{ github.sha }}

      - name: Update Helm values
        run: |
          sed -i "s/tag: .*/tag: ${{ github.sha }}/" helm/values-dev.yaml

      - name: Commit updated values
        run: |
          git config user.email "ci@github.com"
          git config user.name "GitHub Actions"
          git add helm/values-dev.yaml
          git commit -m "Update dev image tag: ${{ github.sha }}" || echo "No changes"
          git push
```

### 🟧 **ci-uat.yaml**

Similar but runs on the `uat` branch:

```yaml
on:
  push:
    branches:
      - uat
```

Updates:

```
helm/values-uat.yaml
```

### 🟥 **ci-prod.yaml**

Runs on tag:

```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

Updates:

```
helm/values-prod.yaml
```

---

# ☸ Kubernetes Deployments via Helm

### `helm/values-dev.yaml` example

```yaml
imageRegistry: ""
image:
  repository: n8n-custom
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  port: 5678

ingress:
  enabled: true
  className: cilium
  host: n8n-dev.local
```

---

# 🚢 Argo CD Setup

### Create the Argo CD App:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n8n-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR/repo.git
    targetRevision: develop
    path: helm
    helm:
      valueFiles:
        - values-dev.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply it:

```sh
kubectl apply -f argo-dev.yaml
```

---

# 🔄 How the Pipeline Works (End‑to‑End)

| Step | Trigger | Action |
|------|---------|--------|
| 1 | Push to `develop` | GitHub Action starts CI/CD |
| 2 | Docker Build | Build + push `n8n-custom:<sha>` |
| 3 | Update Helm values | `values-dev.yaml` tag updated |
| 4 | Commit updated Helm file | GitHub writes new tag back |
| 5 | Argo CD detects change | Auto-sync begins |
| 6 | Kubernetes deploys | New image rolls out |

---

# 🧪 Test the Pipeline

### 1️⃣ Make a code change  
Commit to the branch:

```
develop
```

### 2️⃣ GitHub Actions will:

- Build Docker image
- Push to Docker Hub
- Update Helm
- Commit new values

### 3️⃣ Argo CD will automatically sync:

```
argo app get n8n-dev
```

---

# 📦 Deployment Output

You should see:

```
n8n-custom:<commit-sha>
```

Running in Kubernetes:

```
kubectl get pods -n default
```

---

# 🌐 Access n8n

### Local Dev:

```
http://localhost:5678
```

### Through Ingress:

```
http://n8n-dev.local
```

---

# 🖼 Architecture Diagram (PNG)

![Pipeline Diagram](pipeline-diagram.png)

---

# 🏁 Summary

This repository now includes:

✔ Automated build pipeline  
✔ Branch‑based environments  
✔ Helm-based config promoted between environments  
✔ Argo CD auto-sync  
✔ Dockerized n8n custom build  
✔ Full GitHub Actions automation  

---

# 📄 License

MIT License
