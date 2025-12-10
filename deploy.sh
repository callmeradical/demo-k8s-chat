#!/bin/bash

# This script deploys the Goose demo application to a Kubernetes cluster using Helm.
# This script automates the installation and configuration of required software
# packages and settings, streamlining the setup process for testing and
# demonstration environments.
set -e

echo "🦢 Deploying Goose K8s Demo with Helm"
echo "======================================"

# Check if kubectl is available
if ! command -v kubectl &>/dev/null; then
  echo "❌ kubectl is not installed. Please install kubectl first."
  exit 1
fi

# Check if helm is available
if ! command -v helm &>/dev/null; then
  echo "❌ Helm is not installed. Please install Helm first."
  echo "   Visit: https://helm.sh/docs/intro/install/"
  exit 1
fi

# Check if we have cluster access
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
  exit 1
fi

echo "✅ Prerequisites check passed"

# Check if ANTHROPIC_API_KEY environment variable is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ ANTHROPIC_API_KEY environment variable is not set."
  echo ""
  echo "Please set your Anthropic API key:"
  echo "  export ANTHROPIC_API_KEY='your-anthropic-api-key-here'"
  echo "  ./deploy.sh"
  echo ""
  exit 1
fi

echo "✅ Found ANTHROPIC_API_KEY environment variable"

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t goose-k8s-demo:latest .

# If using kind, load the image
if kubectl config current-context | grep -q "kind"; then
  echo "📦 Loading image to kind cluster..."
  kind load docker-image goose-k8s-demo:latest
  # Use local image for kind
  IMAGE_REPO="goose-k8s-demo"
  IMAGE_TAG="latest"
else
  # Use GHCR image for other environments
  echo "📦 Using GitHub Container Registry image..."
  IMAGE_REPO="ghcr.io/owner-placeholder/repo-placeholder"
  IMAGE_TAG="latest"
fi

# Create namespace if it doesn't exist
kubectl create namespace goose --dry-run=client -o yaml | kubectl apply -f -

# Create or update the secret from environment variable
echo "🔑 Creating/updating secret from ANTHROPIC_API_KEY..."
kubectl create secret generic anthropic-api-key \
  --namespace=goose \
  --from-literal=api-key="$ANTHROPIC_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Installing/Upgrading Helm chart..."

# Deploy with Helm
helm upgrade --install goose-demo ./helm/goose-k8s-demo \
  --namespace goose \
  --set image.repository="$IMAGE_REPO" \
  --set image.tag="$IMAGE_TAG" \
  --wait \
  --timeout=5m

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n goose -o wide
echo ""
echo "🌐 To access Goose web interface:"
echo "   kubectl port-forward -n goose service/goose-demo-goose-k8s-demo 3000:3000"
echo ""
echo "   Then open: http://localhost:3000"
echo ""
echo "📋 To view logs:"
echo "   kubectl logs -n goose deployment/goose-demo-goose-k8s-demo -f"
echo ""
echo "🔧 To check status:"
echo "   kubectl get all -n goose"
echo "   helm status goose-demo -n goose"
echo ""
echo "Happy Kubernetes chatting with Goose! 🦢✨"
