#!/bin/bash

# Enhanced kubeconfig setup for both local and remote Kubernetes clusters
# Handles Docker Desktop, EKS, GKE, AKS, and other cloud providers

set -e

echo "🔧 Enhanced kubeconfig setup for k8s-chat..."

# Detect current cluster context and type
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [ -z "$CURRENT_CONTEXT" ]; then
    echo "❌ No kubectl context found. Please configure kubectl first."
    exit 1
fi

echo "📋 Current context: $CURRENT_CONTEXT"

# Test cluster connectivity
echo "🔍 Testing cluster connectivity..."
if ! kubectl cluster-info --request-timeout=10s >/dev/null 2>&1; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "   Check your kubeconfig and network connectivity"
    exit 1
fi

CLUSTER_INFO=$(kubectl cluster-info | head -1)
echo "✅ Connected to: $CLUSTER_INFO"

# Create temporary kubeconfig directory
TEMP_KUBE_DIR="${HOME}/.kube-docker"
mkdir -p "$TEMP_KUBE_DIR"

# Get cluster endpoint to detect type
CLUSTER_SERVER=$(kubectl config view --minify --output jsonpath='{.clusters[0].cluster.server}')
echo "🌐 Cluster server: $CLUSTER_SERVER"

# Determine cluster type and setup accordingly
if echo "$CLUSTER_SERVER" | grep -q "127.0.0.1\|localhost"; then
    echo "🏠 Local cluster detected (Docker Desktop/Minikube/Kind)"

    # Copy original config and modify for Docker container access
    cp "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config"

    # Determine the correct host mapping based on the system
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Docker Desktop
        DOCKER_HOST="kubernetes.docker.internal"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - use host.docker.internal or docker0 bridge IP
        DOCKER_HOST="host.docker.internal"
    else
        # Windows or other - use generic docker internal
        DOCKER_HOST="host.docker.internal"
    fi

    # Replace localhost references
    sed -i.bak "s/127\.0\.0\.1/$DOCKER_HOST/g" "$TEMP_KUBE_DIR/config"
    sed -i.bak "s/localhost/$DOCKER_HOST/g" "$TEMP_KUBE_DIR/config"

    echo "✅ Modified kubeconfig for container access"
    echo "   Container will connect to: $DOCKER_HOST"

elif echo "$CLUSTER_SERVER" | grep -q "eks\..*\.amazonaws\.com"; then
    echo "☁️  AWS EKS cluster detected"

    # For EKS, copy config as-is since the endpoint is already accessible
    cp "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config"

    # Check if AWS CLI is available for token refresh
    if command -v aws >/dev/null 2>&1; then
        echo "✅ AWS CLI available for token management"
    else
        echo "⚠️  AWS CLI not found - you may need to configure authentication"
    fi

elif echo "$CLUSTER_SERVER" | grep -q "gke\.googleapis\.com\|googleapis\.com"; then
    echo "☁️  Google GKE cluster detected"

    # For GKE, copy config as-is
    cp "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config"

    # Check if gcloud is available
    if command -v gcloud >/dev/null 2>&1; then
        echo "✅ gcloud CLI available for authentication"
    else
        echo "⚠️  gcloud CLI not found - you may need to configure authentication"
    fi

elif echo "$CLUSTER_SERVER" | grep -q "azmk8s\.io\|azure\.com"; then
    echo "☁️  Azure AKS cluster detected"

    # For AKS, copy config as-is
    cp "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config"

    # Check if az CLI is available
    if command -v az >/dev/null 2>&1; then
        echo "✅ Azure CLI available for authentication"
    else
        echo "⚠️  Azure CLI not found - you may need to configure authentication"
    fi

else
    echo "🌐 Remote/Generic cluster detected"
    echo "   Using configuration as-is for remote access"

    # Copy config without modification for remote clusters
    cp "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config"
fi

# Validate the modified config works
echo "🧪 Validating modified kubeconfig..."
if KUBECONFIG="$TEMP_KUBE_DIR/config" kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
    echo "✅ Modified kubeconfig validated successfully"
else
    echo "⚠️  Modified kubeconfig validation failed - falling back to original"
    cp "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config"
fi

# Set permissions
chmod 600 "$TEMP_KUBE_DIR/config"

echo ""
echo "📁 Docker-compatible kubeconfig created at: $TEMP_KUBE_DIR/config"
echo "🔑 The container will use this kubeconfig to access your cluster"

# Show context info
echo ""
echo "📋 Cluster Information:"
echo "  Context: $CURRENT_CONTEXT"
echo "  Server: $CLUSTER_SERVER"
echo "  Config: $TEMP_KUBE_DIR/config"
