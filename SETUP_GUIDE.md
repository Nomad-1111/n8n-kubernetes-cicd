# Complete Setup Guide - n8n Multi-Environment Deployment

**Last Updated**: November 2025  
**Target Platform**: Local PC (Windows, macOS, or Linux)  
**Purpose**: Step-by-step guide to set up n8n deployment from scratch

---

## 📋 Table of Contents

1. [Prerequisites Overview](#prerequisites-overview)
2. [System Requirements](#system-requirements)
3. [Step 1: Choose and Install Your Kubernetes Platform](#step-1-choose-and-install-your-kubernetes-platform)
   - [Option A: Docker Desktop](#option-a-docker-desktop-recommended-for-windowsmacos)
   - [Option B: Minikube](#option-b-minikube-recommended-for-linux-or-advanced-users)
4. [Step 2: Install kubectl](#step-2-install-kubectl)
5. [Step 3: Install Helm](#step-3-install-helm)
6. [Step 4: Install Argo CD](#step-4-install-argo-cd)
7. [Step 5: Install Ingress Controller](#step-5-install-ingress-controller)
   - [For Docker Desktop Users](#for-docker-desktop-users)
   - [For Minikube Users](#for-minikube-users)
8. [Step 6: Set Up Git and GitHub](#step-6-set-up-git-and-github)
9. [Step 7: Set Up Docker Hub](#step-7-set-up-docker-hub)
10. [Step 8: Clone and Configure Repository](#step-8-clone-and-configure-repository)
11. [Step 9: Deploy Argo CD Applications](#step-9-deploy-argo-cd-applications)
12. [Step 10: Verify Deployment](#step-10-verify-deployment)
13. [Troubleshooting](#troubleshooting)

---

## ⚠️ Configuration Required Before Setup

**Before following this guide**, you need to configure the repository with your own values:

### Critical Files to Update:

1. **`.github/workflows/ci-cd.yaml`** - Docker Hub repository name (Lines 152, 159, 184)
2. **`argo/n8n-dev.yaml`, `argo/n8n-uat.yaml`, `argo/n8n-prod.yaml`** - GitHub repository URLs (Line 23/24)
3. **`helm/values-dev.yaml`, `helm/values-uat.yaml`, `helm/values-prod.yaml`** - Docker Hub repository name (Line 80-88)
4. **GitHub Secrets** - Configure `DOCKER_USERNAME` and `DOCKER_PASSWORD` in repository settings

**📖 Complete instructions: See [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration guide with exact file locations and line numbers.**

**⏱️ Estimated time**: 10-15 minutes to configure all files

---

## Prerequisites Overview

This guide will help you install and configure:

1. **Docker Desktop** (or Minikube) - Kubernetes cluster
2. **kubectl** - Kubernetes command-line tool
3. **Helm** - Kubernetes package manager
4. **Argo CD** - GitOps continuous delivery tool
5. **NGINX Ingress Controller** - For external access
6. **Git** - Version control
7. **Docker Hub Account** - For storing Docker images
8. **GitHub Account** - For repository and CI/CD

**Estimated Time**: 1-2 hours for complete setup

---

## System Requirements

### Minimum Requirements

- **OS**: Windows 10/11, macOS 10.15+, or Linux (Ubuntu 20.04+)
- **RAM**: 8GB minimum (16GB recommended)
- **CPU**: 2 cores minimum (4 cores recommended)
- **Disk Space**: 20GB free space
- **Internet**: Required for downloading images and packages

### Software Requirements

- Administrator/sudo access
- PowerShell (Windows) or Terminal (macOS/Linux)
- Web browser

---

## Step 1: Choose and Install Your Kubernetes Platform

You have two options for running Kubernetes locally. Both are fully supported:

- **Docker Desktop**: Integrated solution, good for Windows/macOS users
- **Minikube**: Separate cluster, better ingress support, good for Linux or advanced users

Choose one option below and follow its instructions.

---

### Option A: Docker Desktop (Recommended for Windows/macOS)

Docker Desktop includes Kubernetes, making it convenient for local development.

#### Windows Installation

1. **Download Docker Desktop**:
   - Go to: https://www.docker.com/products/docker-desktop
   - Click "Download for Windows"
   - Download the installer (Docker Desktop Installer.exe)

2. **Install Docker Desktop**:
   - Run the installer as Administrator
   - Follow the installation wizard
   - **Important**: Check "Use WSL 2 instead of Hyper-V" if prompted (recommended)
   - Restart your computer when prompted

3. **Start Docker Desktop**:
   - Launch Docker Desktop from Start menu
   - Wait for Docker to start (whale icon in system tray)
   - Accept the terms of service if prompted

4. **Enable Kubernetes**:
   - Click the Docker Desktop icon in system tray
   - Go to **Settings** (gear icon)
   - Navigate to **Kubernetes** in left sidebar
   - Check **"Enable Kubernetes"**
   - Click **"Apply & Restart"**
   - Wait for Kubernetes to start (green indicator)

5. **Verify Installation**:
   ```powershell
   # Check Docker version
   docker --version
   # Should show: Docker version 24.x.x or similar

   # Check Kubernetes is running
   kubectl get nodes
   # Should show: NAME STATUS ROLES AGE VERSION
   #              docker-desktop Ready control-plane 1m v1.27.x
   ```

6. **Set kubectl context** (if needed):
   ```powershell
   # Verify you're using Docker Desktop context
   kubectl config current-context
   # Should show: docker-desktop

   # If not, switch to it:
   kubectl config use-context docker-desktop
   ```

#### macOS Installation

1. **Download Docker Desktop**:
   - Go to: https://www.docker.com/products/docker-desktop
   - Click "Download for Mac"
   - Choose Intel Chip or Apple Silicon version

2. **Install Docker Desktop**:
   - Open the downloaded `.dmg` file
   - Drag Docker to Applications folder
   - Open Docker from Applications
   - Enter your password when prompted

3. **Enable Kubernetes**:
   - Click Docker icon in menu bar → **Settings**
   - Go to **Kubernetes** tab
   - Check **"Enable Kubernetes"**
   - Click **"Apply & Restart"**

4. **Verify Installation**:
   ```bash
   docker --version
   kubectl get nodes
   ```

5. **Set kubectl context** (if needed):
   ```bash
   kubectl config current-context
   # Should show: docker-desktop
   ```

#### Docker Desktop Notes

- ✅ Integrated with Docker Desktop UI
- ✅ Easy to start/stop from Docker Desktop
- ⚠️ Ingress URLs may not work due to port 80 limitations (use port-forwarding instead)
- ✅ Good for beginners
- ✅ Works well on Windows and macOS

---

### Option B: Minikube (Recommended for Linux, or Advanced Users)

Minikube runs a separate Kubernetes cluster and has better ingress support.

#### Windows Installation

1. **Install Minikube**:
   ```powershell
   # Using Chocolatey (recommended)
   choco install minikube

   # Or download manually from:
   # https://minikube.sigs.k8s.io/docs/start/
   ```

2. **Verify Installation**:
   ```powershell
   minikube version
   # Should show: minikube version: v1.x.x
   ```

#### macOS Installation

1. **Install Minikube**:
   ```bash
   # Using Homebrew (recommended)
   brew install minikube
   ```

2. **Verify Installation**:
   ```bash
   minikube version
   ```

#### Linux Installation

1. **Install Minikube**:
   ```bash
   # Download and install
   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   sudo install minikube-linux-amd64 /usr/local/bin/minikube
   ```

2. **Verify Installation**:
   ```bash
   minikube version
   ```

#### Start Minikube

```powershell
# Start Minikube (this may take a few minutes on first run)
minikube start

# For Windows with Hyper-V:
# minikube start --driver=hyperv

# For Windows with VirtualBox:
# minikube start --driver=virtualbox

# Verify Minikube is running
minikube status
# Should show: host: Running, kubelet: Running, apiserver: Running

# Check Kubernetes nodes
kubectl get nodes
# Should show: minikube   Ready   control-plane   1m   v1.27.x
```

#### Set kubectl context

```powershell
# Verify you're using Minikube context
kubectl config current-context
# Should show: minikube

# If not, switch to it:
kubectl config use-context minikube
```

#### Minikube Notes

- ✅ Better ingress support (ingress URLs actually work!)
- ✅ Separate cluster (doesn't interfere with Docker Desktop)
- ✅ Good for Linux users
- ✅ More control over cluster configuration
- ✅ Can run alongside Docker Desktop
- ⚠️ Requires separate installation
- ⚠️ Uses more resources (separate VM)

---

### Which Should You Choose?

**Choose Docker Desktop if:**
- You're on Windows or macOS
- You want an integrated solution
- You're new to Kubernetes
- You don't need ingress URLs to work

**Choose Minikube if:**
- You're on Linux
- You want ingress URLs to work (`http://n8n-dev.local`)
- You prefer a separate cluster
- You're already using Minikube
- You need more control over the cluster

**Note**: You can have both installed, but only use one at a time. Make sure your kubectl context points to the one you're using.

---

## Step 2: Install kubectl

kubectl is the Kubernetes command-line tool.

**Note for Minikube users**: Minikube automatically installs kubectl, so you may already have it. Verify with `kubectl version --client`. If it's installed, you can skip this step.

### Windows Installation

**Method 1: Using Chocolatey (Recommended)**
```powershell
# Install Chocolatey if not already installed
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install kubectl
choco install kubernetes-cli
```

**Method 2: Using Direct Download**
```powershell
# Download kubectl
$version = "v1.28.0"  # Check latest version at https://kubernetes.io/releases/
$url = "https://dl.k8s.io/release/$version/bin/windows/amd64/kubectl.exe"
Invoke-WebRequest -Uri $url -OutFile "$env:USERPROFILE\kubectl.exe"

# Add to PATH
$env:Path += ";$env:USERPROFILE"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::User)
```

**Method 3: Using Docker Desktop (Automatic)**
- Docker Desktop automatically installs kubectl
- It's available in: `C:\Program Files\Docker\Docker\resources\bin\kubectl.exe`
- Add to PATH or use full path

### macOS Installation

**Method 1: Using Homebrew (Recommended)**
```bash
brew install kubectl
```

**Method 2: Using Direct Download**
```bash
# Download latest version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Linux Installation

```bash
# Download latest version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Verify kubectl Installation

```powershell
# Windows PowerShell or macOS/Linux Terminal
kubectl version --client
# Should show: Client Version: version.Info{Major:"1", Minor:"28", ...}

# Test connection to cluster
kubectl cluster-info
# Should show: Kubernetes control plane is running at https://...
```

---

## Step 3: Install Helm

Helm is the Kubernetes package manager used to deploy n8n.

### Windows Installation

**Method 1: Using Chocolatey**
```powershell
choco install kubernetes-helm
```

**Method 2: Using Direct Download**
```powershell
# Download Helm
$version = "v3.13.0"  # Check latest at https://github.com/helm/helm/releases
$url = "https://get.helm.sh/helm-$version-windows-amd64.zip"
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\helm.zip"

# Extract
Expand-Archive -Path "$env:TEMP\helm.zip" -DestinationPath "$env:TEMP\helm"
Move-Item "$env:TEMP\helm\windows-amd64\helm.exe" "$env:USERPROFILE\helm.exe"

# Add to PATH
$env:Path += ";$env:USERPROFILE"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::User)
```

### macOS Installation

**Method 1: Using Homebrew**
```bash
brew install helm
```

**Method 2: Using Direct Download**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Linux Installation

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Verify Helm Installation

```powershell
# Check Helm version
helm version
# Should show: version.BuildInfo{Version:"v3.13.0", ...}

# Add Helm repositories (required for Argo CD)
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

---

## Step 4: Install Argo CD

Argo CD is the GitOps tool that automatically deploys n8n from Git.

### Installation Steps

1. **Create Argo CD Namespace**:
   ```powershell
   kubectl create namespace argocd
   ```

2. **Install Argo CD**:
   ```powershell
   # Add Argo CD Helm repository
   helm repo add argo https://argoproj.github.io/argo-helm
   helm repo update

   # Install Argo CD
   helm install argocd argo/argo-cd \
     --namespace argocd \
     --create-namespace \
     --set server.service.type=ClusterIP
   ```

   **Alternative: Using kubectl (if Helm fails)**:
   ```powershell
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

3. **Wait for Argo CD to be Ready**:
   ```powershell
   # Watch pods until all are running
   kubectl get pods -n argocd -w
   # Press Ctrl+C when all pods show STATUS: Running (usually takes 2-3 minutes)

   # Or check status
   kubectl get pods -n argocd
   # Should show: argocd-application-controller-0   1/1   Running
   #              argocd-dex-server-xxx            1/1   Running
   #              argocd-redis-xxx                 1/1   Running
   #              argocd-repo-server-xxx           1/1   Running
   #              argocd-server-xxx                1/1   Running
   ```

4. **Get Argo CD Admin Password**:
   ```powershell
   # Get initial admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
   
   # Save this password - you'll need it to login!
   # Default username: admin
   ```

5. **Port-Forward Argo CD Server** (for local access):
   ```powershell
   # In a new terminal, keep this running
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

6. **Access Argo CD UI**:
   - Open browser: https://localhost:8080
   - Accept the self-signed certificate warning
   - Login with:
     - **Username**: `admin`
     - **Password**: (the password from step 4)

### Verify Argo CD Installation

```powershell
# Check Argo CD version
kubectl exec -n argocd deployment/argocd-server -- argocd version --client
# Should show: argocd: v2.8.x

# Check Argo CD applications (should be empty initially)
kubectl get applications -n argocd
```

---

## Step 5: Install Ingress Controller

An ingress controller is needed for external access to n8n via URLs (optional, but recommended).

### For Docker Desktop Users

Docker Desktop requires manual installation of the NGINX Ingress Controller:

```powershell
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Verify installation
kubectl get pods -n ingress-nginx
# Should show: ingress-nginx-controller-xxx   1/1   Running
```

#### Verify Ingress Controller (Docker Desktop)

```powershell
# Check ingress controller service
kubectl get svc -n ingress-nginx ingress-nginx-controller
# Should show: ingress-nginx-controller   NodePort   10.x.x.x   <none>   80:3xxxx/TCP

# Check if port 80 is accessible (may not work on Docker Desktop)
Test-NetConnection -ComputerName localhost -Port 80
# If this fails, port 80 is not accessible (Docker Desktop limitation)
```

**Important for Docker Desktop**: Port 80 may not be accessible, which means ingress URLs (`http://n8n-dev.local`) may timeout. Use port-forwarding instead (see Step 10).

---

### For Minikube Users

Minikube has a built-in ingress addon that's much easier to use:

```powershell
# Enable Minikube ingress addon
minikube addons enable ingress

# Wait for it to be ready (may take 1-2 minutes)
kubectl get pods -n ingress-nginx -w
# Press Ctrl+C when all pods show "Running"

# Verify installation
kubectl get pods -n ingress-nginx
# Should show: ingress-nginx-controller-xxx   1/1   Running
```

#### Get Minikube IP for Hosts File

```powershell
# Get Minikube IP address
minikube ip
# Example output: 192.168.49.2

# Save this IP - you'll need it for the hosts file
$minikubeIP = minikube ip
Write-Host "Minikube IP: $minikubeIP"
```

#### Verify Ingress Controller (Minikube)

```powershell
# Check ingress controller service
kubectl get svc -n ingress-nginx ingress-nginx-controller
# Should show: ingress-nginx-controller   NodePort or LoadBalancer

# Test ingress access
minikube service -n ingress-nginx ingress-nginx-controller --url
# This will show the URL to access the ingress controller
```

**Important for Minikube**: Ingress URLs will work! You can use `http://n8n-dev.local` after configuring the hosts file (see Step 10).

---

### Verify Ingress Controller (Both Platforms)

```powershell
# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Check ingress controller service
kubectl get svc -n ingress-nginx

# View ingress controller logs (if needed)
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50
```

**Note**: For local development, you can skip ingress and use port-forwarding instead (see Step 10). However, Minikube users will find ingress URLs work well.

---

## Step 6: Set Up Git and GitHub

### Install Git

**Windows**:
- Download from: https://git-scm.com/download/win
- Run installer with default options
- Verify: `git --version`

**macOS**:
```bash
# Git usually comes pre-installed
git --version
# If not, install via Homebrew: brew install git
```

**Linux**:
```bash
sudo apt-get update
sudo apt-get install git
```

### Configure Git

```powershell
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

### Set Up GitHub Account

1. **Create GitHub Account** (if you don't have one):
   - Go to: https://github.com/signup
   - Create account and verify email

2. **Fork or Clone Repository**:
   ```powershell
   # Clone the repository
   git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
   cd n8n
   ```

3. **Set Up SSH Keys** (Optional, but recommended):
   ```powershell
   # Generate SSH key
   ssh-keygen -t ed25519 -C "your.email@example.com"
   
   # Copy public key
   cat ~/.ssh/id_ed25519.pub
   # Copy the output and add to GitHub: Settings → SSH and GPG keys → New SSH key
   ```

---

## Step 7: Set Up Docker Hub

Docker Hub is where custom n8n images are stored.

### Create Docker Hub Account

1. **Sign Up**:
   - Go to: https://hub.docker.com/signup
   - Create account and verify email

2. **Create Repository**:
   - Go to: https://hub.docker.com/repositories
   - Click "Create Repository"
   - Name: `n8n-custom`
   - Visibility: Public or Private (your choice)
   - Click "Create"

3. **Get Access Token** (for GitHub Actions):
   - Go to: https://hub.docker.com/settings/security
   - Click "New Access Token"
   - Description: "GitHub Actions CI/CD"
   - Permissions: Read & Write
   - Click "Generate"
   - **SAVE THIS TOKEN** - you'll need it for GitHub secrets

### Test Docker Hub Login

```powershell
# Login to Docker Hub
docker login
# Enter your Docker Hub username and password

# Verify login
docker info | Select-String "Username"
```

---

## Step 8: Clone and Configure Repository

### Clone Repository

```powershell
# Clone the repository
git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
cd n8n

# Check current branch
git branch
# Should show: * develop

# Verify repository structure
ls
# Should show: argo/, helm/, docker/, .github/, etc.
```

### Configure GitHub Secrets (Required for CI/CD)

1. **Go to GitHub Repository**:
   - Navigate to: https://github.com/YOUR-USERNAME/YOUR-REPO-NAME
   - Or your forked repository

2. **Add Secrets**:
   - Go to: **Settings** → **Secrets and variables** → **Actions**
   - Click **"New repository secret"**
   - Add two secrets:
     - **Name**: `DOCKER_USERNAME`
       - **Value**: `YOUR-DOCKERHUB-USERNAME` (or your Docker Hub username)
     - **Name**: `DOCKER_PASSWORD`
       - **Value**: (Your Docker Hub access token from Step 7)

3. **Verify Secrets**:
   - You should see both secrets listed (values are hidden)

### Update Repository URLs (If Using Fork)

If you forked the repository, update these files:

1. **Argo CD Application Files**:
   - `argo/n8n-dev.yaml`
   - `argo/n8n-uat.yaml`
   - `argo/n8n-prod.yaml`
   
   Update `repoURL` to your repository URL:
   ```yaml
   source:
     repoURL: https://github.com/YOUR-USERNAME/n8n.git
   ```

2. **GitHub Actions Workflow** (if needed):
   - `.github/workflows/ci-cd.yaml` should work as-is if you forked

---

## Step 9: Deploy Argo CD Applications

Argo CD applications define what to deploy from Git.

### Deploy All Three Environments

```powershell
# Make sure you're in the repository root
cd n8n

# Deploy dev environment
kubectl apply -f argo/n8n-dev.yaml

# Deploy UAT environment
kubectl apply -f argo/n8n-uat.yaml

# Deploy prod environment
kubectl apply -f argo/n8n-prod.yaml
```

### Verify Argo CD Applications

```powershell
# Check applications
kubectl get applications -n argocd
# Should show:
# NAME       SYNC STATUS   HEALTH STATUS
# n8n-dev    Synced       Healthy
# n8n-uat    Synced       Healthy
# n8n-prod   Synced       Healthy

# Watch sync status
kubectl get applications -n argocd -w
# Press Ctrl+C when all show "Synced"
```

### Check Argo CD UI

1. **Port-forward Argo CD** (if not already running):
   ```powershell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. **Open Browser**:
   - Go to: https://localhost:8080
   - Login with admin credentials
   - You should see three applications: `n8n-dev`, `n8n-uat`, `n8n-prod`

---

## Step 10: Verify Deployment

### Check Pods Are Running

```powershell
# Check dev environment
kubectl get pods -n n8n-dev
# Should show: n8n-api-xxx   1/1   Running

# Check UAT environment
kubectl get pods -n n8n-uat
# Should show: n8n-api-xxx   1/1   Running

# Check prod environment
kubectl get pods -n n8n-prod
# Should show: n8n-api-xxx   1/1   Running (2 pods for prod)
```

### Check Services

```powershell
# Check services
kubectl get svc -n n8n-dev
kubectl get svc -n n8n-uat
kubectl get svc -n n8n-prod
# Should all show: workflow-api-svc   ClusterIP   10.x.x.x   5678/TCP
```

### Access n8n

#### Option 1: Port-Forward (Works for Both Docker Desktop and Minikube) ⭐ RECOMMENDED FOR DOCKER DESKTOP

Port-forwarding is the most reliable method for Docker Desktop and also works great for Minikube:

```powershell
# Dev environment (in separate terminal)
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
# Access: http://localhost:5678

# UAT environment (in separate terminal)
kubectl port-forward -n n8n-uat svc/workflow-api-svc 5679:5678
# Access: http://localhost:5679

# Prod environment (in separate terminal)
kubectl port-forward -n n8n-prod svc/workflow-api-svc 5680:5678
# Access: http://localhost:5680
```

**Helper Script**: Run `.\start-n8n-port-forwards.ps1` from the repository root to start all port-forwards automatically.

---

#### Option 2: Ingress URLs (Minikube Only - Actually Works!)

**For Minikube users**, ingress URLs will work properly:

1. **Get Minikube IP**:
   ```powershell
   minikube ip
   # Example: 192.168.49.2
   ```

2. **Update Hosts File** (run PowerShell as Administrator):
   ```powershell
   $minikubeIP = minikube ip
   Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "$minikubeIP  n8n-dev.local"
   Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "$minikubeIP  n8n-uat.local"
   ipconfig /flushdns
   ```

3. **Access n8n**:
   - Dev: `http://n8n-dev.local`
   - UAT: `http://n8n-uat.local`
   - Prod: `http://n8n.yourdomain.com` (if configured)

**Note for Docker Desktop users**: Ingress URLs may timeout due to port 80 limitations. Use port-forwarding (Option 1) instead.

---

#### Option 3: Minikube Service Command (Minikube Only)

Minikube provides a convenient command to open services:

```powershell
# Open dev environment in browser
minikube service -n n8n-dev workflow-api-svc

# Or get the URL
minikube service -n n8n-dev workflow-api-svc --url
```

---

**See `ACCESS_N8N.md` for detailed access instructions and troubleshooting.**

### Verify n8n is Working

1. **Open Browser**: http://localhost:5678
2. **Create Account**: First-time setup will prompt for admin account
3. **Verify Access**: You should see n8n dashboard

---

## Platform-Specific Notes

### Using Minikube

If you're using Minikube (see [Step 1: Option B](#option-b-minikube-recommended-for-linux-or-advanced-users)), note that:

- Minikube has better ingress support than Docker Desktop
- Ingress URLs (`http://n8n-dev.local`) will work properly with Minikube
- Use `minikube ip` to get the IP for your hosts file
- Use `minikube service` command for easy access to services
- See [Step 5: For Minikube Users](#for-minikube-users) for ingress setup
- See [Step 10: Option 2](#option-2-ingress-urls-minikube-only---actually-works) for access methods

### Using Docker Desktop

If you're using Docker Desktop (see [Step 1: Option A](#option-a-docker-desktop-recommended-for-windowsmacos)), note that:

- Port-forwarding is the most reliable access method
- Ingress URLs may timeout due to port 80 limitations
- See [Step 5: For Docker Desktop Users](#for-docker-desktop-users) for ingress setup
- See [Step 10: Option 1](#option-1-port-forward-works-for-both-docker-desktop-and-minikube--recommended-for-docker-desktop) for access methods

---

## Troubleshooting

### Docker Desktop Kubernetes Not Starting

**Problem**: Kubernetes shows "Stopped" in Docker Desktop

**Solution**:
```powershell
# Reset Kubernetes cluster
# Docker Desktop → Settings → Kubernetes → Reset Kubernetes Cluster

# Or via command line
kubectl delete --all pods --all-namespaces
```

### kubectl Connection Refused

**Problem**: `kubectl get nodes` shows "connection refused"

**Solution**:
```powershell
# Check Docker Desktop is running
# Check Kubernetes is enabled in Docker Desktop settings
# Restart Docker Desktop
```

### Argo CD Pods Not Starting

**Problem**: Argo CD pods stuck in "Pending" or "CrashLoopBackOff"

**Solution**:
```powershell
# Check pod logs
kubectl logs -n argocd <pod-name>

# Check resource limits
kubectl describe pod -n argocd <pod-name>

# Increase Docker Desktop resources:
# Docker Desktop → Settings → Resources → Increase Memory/CPU
```

### Port Already in Use

**Problem**: Port-forward fails with "port already in use"

**Solution**:
```powershell
# Find process using port (Windows)
netstat -ano | findstr :5678

# Kill process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Or use different port
kubectl port-forward -n n8n-dev svc/workflow-api-svc 56780:5678
```

### Argo CD Applications Out of Sync

**Problem**: Applications show "OutOfSync" status

**Solution**:
```powershell
# Force refresh
kubectl patch application n8n-dev -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"develop"}}}'

# Or sync via UI: Click "Sync" button in Argo CD UI
```

### Image Pull Errors

**Problem**: Pods show "ImagePullBackOff" error

**Solution**:
```powershell
# Check image name and tag
kubectl describe pod -n n8n-dev <pod-name>

# Verify Docker Hub credentials if using private images
# Check Helm values file has correct image repository
```

### Ingress Not Working

**Problem**: Can't access via ingress hostname

**Solution**:
```powershell
# Check ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl get ingress -n n8n-dev

# For local development, use port-forward instead (see ACCESS_N8N.md)
```

---

## Quick Reference Commands

```powershell
# Check cluster status
kubectl cluster-info
kubectl get nodes

# Check all namespaces
kubectl get namespaces

# Check pods in all n8n namespaces
kubectl get pods -n n8n-dev
kubectl get pods -n n8n-uat
kubectl get pods -n n8n-prod

# Check Argo CD applications
kubectl get applications -n argocd

# View logs
kubectl logs -n n8n-dev -l app=n8n-api

# Restart deployment
kubectl rollout restart deployment/n8n-api -n n8n-dev

# Port-forward all environments
# Terminal 1:
kubectl port-forward -n n8n-dev svc/workflow-api-svc 5678:5678
# Terminal 2:
kubectl port-forward -n n8n-uat svc/workflow-api-svc 5679:5678
# Terminal 3:
kubectl port-forward -n n8n-prod svc/workflow-api-svc 5680:5678
```

---

## Next Steps

After completing setup:

1. **Read Documentation**:
   - `ACCESS_N8N.md` - How to access n8n
   - `CI_CD_PROCESS.md` - Understanding the CI/CD pipeline
   - `SECURITY_SCANNING.md` - Security scanning information

2. **Configure CI/CD**:
   - Ensure GitHub secrets are set (Step 8)
   - Push to `develop` branch to trigger first build

3. **Customize Configuration**:
   - Update `helm/values-*.yaml` files for your needs
   - Configure production domain in `values-prod.yaml`

4. **Monitor Deployments**:
   - Use Argo CD UI to monitor application status
   - Check GitHub Actions for build status

---

## Getting Help

If you encounter issues:

1. **Check Logs**:
   ```powershell
   kubectl logs -n n8n-dev -l app=n8n-api
   kubectl logs -n argocd deployment/argocd-server
   ```

2. **Check Documentation**:
   - `ACCESS_N8N.md` - Access and troubleshooting
   - `CI_CD_PROCESS.md` - CI/CD workflow and troubleshooting
   - `SECURITY_SCANNING.md` - Security scanning and findings

3. **Verify Setup**:
   - Re-run verification commands from each step
   - Check all prerequisites are installed

---

**Congratulations!** 🎉 You've successfully set up n8n multi-environment deployment on your local PC!

