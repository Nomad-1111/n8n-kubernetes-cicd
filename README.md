# n8n Kubernetes Deployment with Full CI/CD Pipeline

A production-ready, enterprise-grade deployment solution for [n8n](https://n8n.io) workflow automation with complete CI/CD automation, multi-environment support, and GitOps integration.

---

## 🎯 What is This Project?

This repository provides a **complete, automated CI/CD pipeline** for deploying n8n to Kubernetes. Unlike standard Helm charts that only deploy n8n, this project includes:

- ✅ **Full CI/CD Automation** - GitHub Actions builds, scans, and deploys automatically
- ✅ **Multi-Environment Support** - Separate dev, UAT, and production environments
- ✅ **GitOps Deployment** - Argo CD automatically syncs deployments from Git
- ✅ **Custom Docker Images** - Build and version your own n8n images
- ✅ **Security Scanning** - Automated vulnerability scanning with Trivy and CodeQL
- ✅ **Database Flexibility** - Support for SQLite (default) and PostgreSQL
- ✅ **Production Ready** - Ingress, persistent storage, and high availability support

---

## 🚀 Use Cases

### 1. **Enterprise Workflow Automation Platform**
Deploy n8n as a centralized workflow automation platform with proper CI/CD:
- Automate business processes across multiple services
- Integrate different APIs and systems
- Create complex workflows with visual interface
- Schedule and trigger workflows automatically
- **Multi-environment workflow testing** before production

### 2. **CI/CD Integration Hub**
Use n8n to automate your development and deployment processes:
- Trigger builds and deployments based on events
- Send notifications on pipeline status
- Automate code reviews and approvals
- Integrate with GitHub, GitLab, Jenkins, and more
- **Automated workflow deployment** through this same pipeline

### 3. **Multi-Environment Development Workflow**
Perfect for teams that need proper dev → UAT → production promotion:
- **Development**: Test new workflows and integrations safely
- **UAT**: Validate workflows before production deployment
- **Production**: Run critical business workflows with high availability
- **Automated promotion** through branch-based deployment

### 4. **API Integration Hub**
Connect disparate systems and services:
- REST API integrations
- Database connections (PostgreSQL, MySQL, MongoDB)
- Cloud service integrations (AWS, Azure, GCP)
- Custom webhook endpoints
- Data transformation and routing

### 5. **Scheduled Tasks and Monitoring**
Automate scheduled operations:
- Daily/weekly/monthly report generation
- System health checks and monitoring
- Data synchronization between systems
- Automated backups and maintenance tasks

### 6. **Business Process Automation**
Streamline business operations:
- Customer onboarding workflows
- Order processing automation
- Invoice and payment processing
- Email marketing automation
- Customer support ticket routing

---

## 🆚 How This Differs from Community Helm Charts

### Community Helm Charts

Popular community charts like:
- **[8gears/n8n-helm-chart](https://github.com/8gears/n8n-helm-chart)** - General-purpose n8n deployment
- **[community-charts/n8n](https://artifacthub.io/packages/helm/community-charts/n8n)** - Standard n8n Helm chart

**What they provide:**
- ✅ Basic n8n deployment to Kubernetes
- ✅ Configurable values for n8n settings
- ✅ Ingress, persistence, and service configuration
- ✅ Support for scaling and worker nodes
- ✅ Redis integration for queue mode

**What they don't provide:**
- ❌ CI/CD automation
- ❌ Multi-environment support
- ❌ GitOps integration
- ❌ Custom Docker image building
- ❌ Automated security scanning
- ❌ Branch-based deployment strategy

---

### This Project - Full CI/CD Solution

**What this project provides:**

#### 1. **Complete CI/CD Pipeline**
- **GitHub Actions** automatically builds Docker images on every push
- **Automated security scanning** with Trivy and CodeQL
- **Helm chart validation** before deployment
- **Automatic image tagging** based on branch names
- **Self-updating Helm values** - workflow updates values files automatically

#### 2. **Multi-Environment Support**
- **Separate configurations** for dev, UAT, and production
- **Branch-based deployment** - `develop` → dev, `uat` → UAT, `main` → production
- **Environment-specific values** - different replicas, storage, and settings per environment
- **Automated promotion** through Git branch workflow

#### 3. **GitOps Integration**
- **Argo CD** automatically syncs deployments from Git
- **Auto-healing** - Argo CD corrects manual changes
- **Prune mode** - Removes resources not in Git
- **Git as source of truth** - All changes tracked in version control

#### 4. **Custom Docker Images**
- **Build your own images** with customizations
- **Version control** - Images tagged by branch name
- **Custom Dockerfile** - Add your own packages or configurations
- **Automated builds** - No manual Docker build/push needed

#### 5. **Enterprise Features**
- **Security scanning** integrated into CI/CD
- **Database flexibility** - Easy switch between SQLite and PostgreSQL
- **Comprehensive documentation** - Step-by-step guides
- **Production-ready** - Includes all best practices

---

## 📊 Comparison Table

| Feature | Community Charts | This Project |
|---------|------------------|--------------|
| **Basic n8n Deployment** | ✅ Yes | ✅ Yes |
| **CI/CD Automation** | ❌ No | ✅ Yes (GitHub Actions) |
| **Multi-Environment** | ❌ Manual setup | ✅ Automated (dev/uat/prod) |
| **GitOps (Argo CD)** | ❌ No | ✅ Yes (auto-sync) |
| **Custom Docker Images** | ❌ Uses official | ✅ Builds custom images |
| **Security Scanning** | ❌ Manual | ✅ Automated (Trivy + CodeQL) |
| **Branch-based Deployment** | ❌ No | ✅ Yes |
| **Auto-update Helm Values** | ❌ Manual | ✅ Automated |
| **Documentation** | Basic | ✅ Comprehensive |
| **Production Ready** | ✅ Yes | ✅ Yes (with CI/CD) |

---

## 🎯 When to Use Each

### Use Community Helm Charts If:
- ✅ You want a **quick, simple deployment** of n8n
- ✅ You don't need **CI/CD automation**
- ✅ You're deploying to a **single environment**
- ✅ You're okay with **manual updates** and deployments
- ✅ You want to use the **official n8n Docker image**
- ✅ You prefer **minimal setup** and configuration

**Example**: Personal projects, small teams, proof-of-concept deployments

### Use This Project If:
- ✅ You need **automated CI/CD** for n8n deployments
- ✅ You want **multi-environment support** (dev/uat/prod)
- ✅ You prefer **GitOps** workflow (Argo CD)
- ✅ You want to **build custom Docker images**
- ✅ You need **automated security scanning**
- ✅ You want **branch-based deployment** strategy
- ✅ You're deploying to **production** with proper workflows
- ✅ You want **comprehensive documentation** and guides

**Example**: Enterprise deployments, teams with multiple environments, production workloads

---

## 🏗 Architecture

```
Developer Commit / PR
        │
        ▼
 GitHub Actions
   ├── Build Docker Image
   ├── Security Scan (Trivy)
   ├── Validate Helm Charts
   ├── Push to Docker Hub
   └── Update Helm Values
        │
        ▼
   Argo CD (Auto-Sync)
   ├── Detects Changes
   ├── Syncs Deployment
   └── Kubernetes Deploys
```

---

## 📋 Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
   cd YOUR-REPO-NAME
   ```

2. **Configure your settings** (see [CONFIGURATION.md](CONFIGURATION.md)):
   - Update Docker Hub repository name
   - Update GitHub repository URLs
   - Configure timezone and domain settings

3. **Follow the setup guide**:
   - See [SETUP_GUIDE.md](SETUP_GUIDE.md) for complete installation instructions

4. **Deploy**:
   ```bash
   kubectl apply -f argo/n8n-dev.yaml
   ```

---

## ⚠️ Before You Start - Configuration Required

**IMPORTANT**: This repository uses placeholders that must be replaced before use.

### Quick Configuration Checklist

Before deploying, you **must** update these files:

1. **`.github/workflows/ci-cd.yaml`** (Lines 152, 159, 184)
   - Replace `YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME` with your Docker Hub repository

2. **`argo/n8n-*.yaml`** (All three files - Line 23/24)
   - Replace `YOUR-USERNAME/YOUR-REPO-NAME` with your GitHub repository URL

3. **`helm/values-*.yaml`** (All three files - Line 80-88)
   - Replace `YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME` with your Docker Hub repository

4. **GitHub Secrets** (Configure in GitHub Settings)
   - Add `DOCKER_USERNAME` and `DOCKER_PASSWORD` secrets

**📖 See [CONFIGURATION.md](CONFIGURATION.md) for detailed step-by-step instructions with exact line numbers and examples.**

---

## 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete installation and setup guide
- **[CONFIGURATION.md](CONFIGURATION.md)** - Configuration guide for customizing the deployment
- **[CI_CD_PROCESS.md](CI_CD_PROCESS.md)** - CI/CD workflow documentation
- **[ACCESS_N8N.md](ACCESS_N8N.md)** - How to access n8n after deployment
- **[SECURITY_SCANNING.md](SECURITY_SCANNING.md)** - Security scanning information

---

## ⚙️ Requirements

- Kubernetes cluster (Docker Desktop, Minikube, or cloud provider)
- kubectl installed and configured
- Helm 3.x installed
- Argo CD installed (for GitOps)
- Docker Hub account (for image storage)
- GitHub account (for CI/CD)

---

## 🔧 Configuration Required

Before using this repository, you need to update several hardcoded references:

1. **Docker Hub Repository** - Update `YOUR-DOCKERHUB-USERNAME/YOUR-REPO-NAME` to your repository
2. **GitHub Repository URLs** - Update `YOUR-USERNAME/YOUR-REPO-NAME` to your repository
3. **Timezone** - Update `Australia/Sydney` to your timezone (optional)
4. **Production Domain** - Update `n8n.yourdomain.com` to your domain

**See [CONFIGURATION.md](CONFIGURATION.md) for detailed instructions.**

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

MIT License - see LICENSE file for details

---

## 🙏 Acknowledgments

- [n8n](https://n8n.io) - The amazing workflow automation tool
- [Argo CD](https://argo-cd.readthedocs.io/) - GitOps continuous delivery
- [Helm](https://helm.sh/) - Kubernetes package manager
- [8gears/n8n-helm-chart](https://github.com/8gears/n8n-helm-chart) - Inspiration for Helm chart structure
