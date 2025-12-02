# 🦢 K8s Chat

**Kubernetes AI Assistant** - A simple demo that creates a Kubernetes secret from an environment variable and launches Goose for cluster management.

## 🚀 Quick Start

### Local Development
```bash
# 1. Set your API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 2. Run locally (creates secret + launches goose)
make run-local
```

### Kubernetes Deployment
```bash
# 1. Set your API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 2. Deploy to Kubernetes
make helm-install

# 3. Access the service
kubectl port-forward svc/k8s-chat 3000:3000
```

Then visit http://localhost:3000

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `make setup` | Verify prerequisites |
| `make build` | Build Docker image |
| `make create-secret` | Create Kubernetes secret from ANTHROPIC_API_KEY |
| `make run-local` | Run locally with Goose |
| `make helm-install` | Deploy to Kubernetes |
| `make helm-uninstall` | Remove from Kubernetes |
| `make clean` | Clean up local images |

## 🏗️ How It Works

1. **Secret Creation**: The `setup-and-run.sh` script creates a Kubernetes secret from your `ANTHROPIC_API_KEY` environment variable
2. **Goose Configuration**: Creates a simple YAML config for the Anthropic provider
3. **Web Interface**: Launches Goose's built-in web server on port 3000
4. **Kubernetes Access**: Uses service account authentication for cluster access

## ⚡ Prerequisites

- **ANTHROPIC_API_KEY** environment variable set
- **kubectl** configured for your cluster
- **helm** installed (for Kubernetes deployment)
- **Docker** (for building images)

## 📁 Key Files

- `setup-and-run.sh` - Main setup script that creates secret and launches Goose
- `Dockerfile` - Simple container with Goose + kubectl
- `Makefile` - Build and deployment commands
- `helm/k8s-chat/` - Helm chart for Kubernetes deployment

## 🔒 Security Note

The API key is:
- ✅ Collected from environment variable (not stored in Git)
- ✅ Stored as a Kubernetes secret
- ✅ Never logged or exposed in container images

## 📁 Project Structure

```
├── helm/                 # Helm charts
│   └── k8s-chat/                    # Main Helm chart
├── deployments/          # Deployment configurations
│   ├── docker/           # Docker Compose files
│   ├── argocd/           # ArgoCD applications
│   └── k8s/              # Kubernetes resources
├── docs/                 # Documentation
│   ├── ARCHITECTURE.md              # Detailed architecture
│   └── KUBERNETES_AUTH_SETUP.md    # K8s auth guide
├── .devcontainer/        # Development container config
├── setup-and-run.sh     # Main setup and launch script
├── Dockerfile            # Container build definition
└── Makefile             # Development commands
```

---

**Perfect for demos and development** • Simple setup • Works with any Kubernetes cluster
