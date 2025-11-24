#!/bin/bash

# 🚀 Deploy Real Goose K8s Chat to Kubernetes Cluster
# This script deploys the containerized Real Goose to your K8s cluster

set -e

echo "🦢 Real Goose K8s Chat - Kubernetes Deployment"
echo "============================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed or not in PATH"
    exit 1
fi

# Check if API key is provided
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ ANTHROPIC_API_KEY environment variable is required"
    echo "   Set it with: export ANTHROPIC_API_KEY='your-api-key-here'"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Build the Docker image locally (for kind/minikube)
echo "🔨 Building Docker image..."
docker build -f Dockerfile.goose -t demo-k8s-chat-goose-web:latest .

# Load image into kind cluster if using kind
if kubectl config current-context | grep -q "kind-"; then
    echo "🔄 Loading image into kind cluster..."
    kind load docker-image demo-k8s-chat-goose-web:latest
fi

# Create secret for API key
echo "🔐 Creating secret for API key..."
kubectl create secret generic k8s-chat-anthropic \
    --from-literal=api-key="$ANTHROPIC_API_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy using Helm
echo "🚀 Deploying with Helm..."

# Check if we should use local values (for local development)
if [ "$USE_LOCAL_IMAGE" = "true" ]; then
    echo "📦 Using local Docker image configuration..."
    helm upgrade --install k8s-chat ./helm/k8s-chat \
        --values values-local.yaml \
        --set secrets.anthropic.apiKey="$ANTHROPIC_API_KEY" \
        --wait
else
    echo "📦 Using registry image configuration..."
    helm upgrade --install k8s-chat ./helm/k8s-chat \
        --set secrets.anthropic.apiKey="$ANTHROPIC_API_KEY" \
        --wait
fi

# Get service information
echo "📋 Getting service information..."
NODE_PORT=$(kubectl get svc k8s-chat -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "✅ Deployment completed!"
echo "🌐 Access Real Goose at: http://$NODE_IP:$NODE_PORT"
echo "   (or http://localhost:$NODE_PORT if using port-forward)"
echo ""
echo "📋 Useful commands:"
echo "   kubectl get pods                 # Check pod status"
echo "   kubectl logs -l app.kubernetes.io/name=k8s-chat  # View logs"
echo "   kubectl port-forward svc/k8s-chat 3000:3000      # Port forward to localhost"
echo "   helm uninstall k8s-chat         # Remove deployment"
echo ""
echo "🎉 Happy Kubernetes chatting with Real Goose!"
