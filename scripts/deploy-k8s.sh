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

# Determine deployment strategy based on cluster type
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_SERVER=$(kubectl config view --minify --output jsonpath='{.clusters[0].cluster.server}')

echo "📋 Deployment context: $CURRENT_CONTEXT"
echo "🌐 Cluster server: $CLUSTER_SERVER"

# Detect cluster type and handle image strategy
if echo "$CLUSTER_SERVER" | grep -q "127.0.0.1\|localhost"; then
    echo "🏠 Local cluster detected - building and loading image locally"

    # Build the Docker image locally
    echo "🔨 Building Docker image..."
    docker build -f Dockerfile.goose -t demo-k8s-chat-goose-web:latest .

    # Load image into local cluster
    if echo "$CURRENT_CONTEXT" | grep -q "kind-"; then
        echo "🔄 Loading image into kind cluster..."
        kind load docker-image demo-k8s-chat-goose-web:latest
    elif echo "$CURRENT_CONTEXT" | grep -q "minikube"; then
        echo "🔄 Loading image into minikube..."
        minikube image load demo-k8s-chat-goose-web:latest
    else
        echo "✅ Image built for local Docker Desktop cluster"
    fi

    USE_LOCAL_IMAGE="true"

else
    echo "☁️  Remote cluster detected - will use registry image"
    echo "⚠️  Make sure the image is pushed to a registry accessible by the cluster"

    # For remote clusters, we should use registry images
    USE_LOCAL_IMAGE="false"

    # Build and tag for potential registry push
    if [ -n "$REGISTRY" ]; then
        echo "🔨 Building and tagging image for registry: $REGISTRY"
        docker build -f Dockerfile.goose -t "$REGISTRY/demo-k8s-chat-goose-web:latest" .
        echo "📤 Pushing to registry..."
        docker push "$REGISTRY/demo-k8s-chat-goose-web:latest"
    else
        echo "⚠️  No REGISTRY environment variable set for remote deployment"
        echo "   Either set REGISTRY and push the image, or use local values for testing"
        USE_LOCAL_IMAGE="true"
    fi
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
