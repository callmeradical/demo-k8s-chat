# Goose Kubernetes Demo

A minimal Helm chart for deploying [Goose](https://github.com/block/goose) AI assistant in Kubernetes for cluster demos and management. Interact with your Kubernetes cluster using natural language through Goose's AI assistant powered by Anthropic.

## 🚀 Quick Start

### Prerequisites
- Docker and kubectl installed
- Helm 3.x installed
- Kubernetes cluster access
- Anthropic API key

### Deploy with One Command

```bash
# Set your API key and deploy
export ANTHROPIC_API_KEY="your-anthropic-api-key-here"
./deploy.sh
```

The deploy script will automatically:
- ✅ Create the `goose` namespace
- ✅ Create the secret from your environment variable
- ✅ Build and deploy the Helm chart
- ✅ Use local images for kind, GHCR images for other clusters

### Access the Web Interface

```bash
# Port forward to access the web interface
kubectl port-forward -n goose service/goose-demo-goose-k8s-demo 3000:3000
```

Open http://localhost:3000 in your browser.

## 💬 Natural Language Demo Commands

Once deployed, try these natural language commands in the Goose interface:

### Basic Cluster Information
- **"List all pods"** → `kubectl get pods --all-namespaces`
- **"Show me the nodes in this cluster"** → `kubectl get nodes`
- **"What namespaces exist?"** → `kubectl get namespaces`

### Pod Management
- **"Show pods in the default namespace"** → `kubectl get pods -n default`
- **"Get details about pod [pod-name]"** → `kubectl describe pod [pod-name]`
- **"Show logs for the failing pod"** → `kubectl logs [pod-name]`
- **"What pods are not running?"** → Intelligent filtering and analysis

### Deployments and Services
- **"Scale the nginx deployment to 3 replicas"** → `kubectl scale deployment nginx --replicas=3`
- **"Show me resource usage"** → `kubectl top nodes` and `kubectl top pods`
- **"List all services in kube-system"** → `kubectl get svc -n kube-system`

## 🛠 Alternative Deployment Methods

### Manual Step-by-Step

If you prefer manual control:

```bash
# 1. Build the image
docker build -t goose-k8s-demo:latest .

# 2. Create namespace
kubectl create namespace goose

# 3. Create secret
kubectl create secret generic anthropic-api-key \
  --namespace=goose \
  --from-literal=api-key='your-anthropic-api-key-here'

# 4. Deploy with Helm
helm upgrade --install goose-demo ./helm/goose-k8s-demo \
  --namespace goose \
  --wait

# 5. Check deployment
kubectl get pods -n goose
```

### Using Published Images

Use pre-built images from GitHub Container Registry:

```bash
# Deploy using published image
helm upgrade --install goose-demo ./helm/goose-k8s-demo \
  --namespace goose \
  --set image.repository=ghcr.io/your-username/your-repo \
  --set image.tag=latest \
  --create-namespace
```

## ⚙️ Configuration

The chart can be customized through Helm values:

```yaml
# Image configuration
image:
  repository: goose-k8s-demo
  tag: latest

# Secret configuration
secret:
  name: "anthropic-api-key"
  key: "api-key"

# Resource limits
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
```

Deploy with custom values:

```bash
helm upgrade --install goose-demo ./helm/goose-k8s-demo \
  --namespace goose \
  --set image.tag=v1.15.0 \
  --set resources.requests.memory=128Mi \
  --wait
```

## 🚀 CI/CD Pipeline

This repository includes automated GitHub Actions workflows for:

### 📦 Container Registry (GHCR)
- Builds multi-platform container images (AMD64 + ARM64)
- Pushes to GitHub Container Registry on pushes/tags
- **Available at**: `ghcr.io/OWNER/REPO:latest`

### ⚓ Helm Chart Repository
- Packages and publishes Helm chart to GitHub Pages
- Creates GitHub releases with semantic versioning
- **Available at**: `https://OWNER.github.io/REPO`

### Setup Requirements

To enable CI/CD after forking:

1. **Enable GitHub Pages**: Settings → Pages → Source: GitHub Actions

2. **Update placeholders** in these files:
   - `.github/cr.yaml` - Replace `owner-placeholder` and `repo-placeholder`
   - `helm/goose-k8s-demo/values.yaml` - Update image repository
   - `deploy.sh` - Update GHCR image path

3. **Use published artifacts**:
   ```bash
   # Add Helm repository
   helm repo add goose-repo https://OWNER.github.io/REPO
   helm install goose-demo goose-repo/goose-k8s-demo --namespace goose
   ```

## 🏗️ Architecture

```
┌─────────────────────────────────┐
│         goose namespace         │
│                                 │
│  ┌─────────────────────────┐    │
│  │     Goose Container     │    │
│  │  • Web Interface        │    │
│  │  • kubectl CLI          │    │
│  │  • Anthropic AI         │    │
│  │  • Developer Extension  │    │
│  └─────────────────────────┘    │
│                                 │
│  ConfigMap: goose-config        │
│  Secret: anthropic-api-key      │
│  ServiceAccount: RBAC enabled   │
└─────────────────────────────────┘
```

## 🧹 Cleanup

```bash
# Quick cleanup
./cleanup.sh

# Manual cleanup
helm uninstall goose-demo -n goose
kubectl delete namespace goose
```

## 🐛 Troubleshooting

### Secret Issues
```bash
# Check if secret exists
kubectl get secret anthropic-api-key -n goose

# Recreate if needed
export ANTHROPIC_API_KEY="your-key"
./deploy.sh
```

### Pod Issues
```bash
# Check pod status and logs
kubectl get pods -n goose
kubectl describe pod -n goose [pod-name]
kubectl logs -n goose [pod-name]
```

### Access Issues
```bash
# Verify service and port-forward
kubectl get service -n goose
kubectl port-forward -n goose service/goose-demo-goose-k8s-demo 3000:3000
```

## 📁 Project Structure

```
├── Dockerfile                      # Container image definition
├── deploy.sh                       # One-command deployment
├── cleanup.sh                      # Cleanup script
├── .github/workflows/               # CI/CD pipelines
├── helm/goose-k8s-demo/            # Helm chart
└── README.md                       # This file
```

## 🔗 Links

- [Goose Project](https://github.com/block/goose)
- [Anthropic API](https://console.anthropic.com/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

Happy Kubernetes chatting with Goose! 🦢✨
