# K8s Chat - Kubernetes Assistant Demo

A containerized chat interface using the Goose AI framework for Kubernetes cluster management.

## 🚀 Quick Start

**Prerequisites:**
- Docker and kubectl installed
- Kubernetes cluster access
- Anthropic API key

**Run locally:**
```bash
# 1. Set your API key
export ANTHROPIC_API_KEY="your-key-here"

# 2. Start the demo
make local-start

# 3. Visit http://localhost:3000
```

**Deploy to Kubernetes:**
```bash
# Option 1: Use local Helm chart
make k8s-deploy
make k8s-status

# Option 2: Use published Helm chart from DockerHub
export ANTHROPIC_API_KEY="your-key-here"
helm install k8s-chat-demo oci://docker.io/YOUR_DOCKERHUB_USERNAME/k8s-chat \
  --set secrets.anthropic.apiKey="$ANTHROPIC_API_KEY" \
  --namespace demo --create-namespace

# Option 3: Deploy with ArgoCD (see ARGOCD-DEPLOYMENT.md)
kubectl apply -f argocd-application.yaml
```

## 💬 Usage

Chat with your Kubernetes assistant:
- "Show me all pods in the default namespace"
- "Scale the frontend deployment to 3 replicas"
- "What's wrong with my failing pods?"

The assistant uses kubectl commands to interact with your cluster in real-time.

## ⚙️ Configuration

Set environment variables:
```bash
ANTHROPIC_API_KEY=your-api-key-here
GOOSE_MODEL=claude-3-5-sonnet-20241022  # Optional
```

## 🛠️ Development

Key files:
- `Makefile` - Main commands (`make help` for full list)
- `Dockerfile.goose` - Container definition
- `goose-config.yaml` - AI agent configuration
- `helm/k8s-chat/` - Kubernetes deployment

Run `make info` to check prerequisites and see available commands.
