#!/bin/bash

# Create a modified kubeconfig that works inside Docker containers
# This replaces localhost/127.0.0.1 with host.docker.internal

set -e

echo "📁 Setting up kubeconfig for containerized access..."

# Create temporary kubeconfig directory
TEMP_KUBE_DIR="${HOME}/.kube-docker"
mkdir -p "$TEMP_KUBE_DIR"

# Copy the original kubeconfig
cp "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config"

# Replace localhost references with kubernetes.docker.internal (proper Docker Desktop host)
sed -i.bak 's/127\.0\.0\.1/kubernetes.docker.internal/g' "$TEMP_KUBE_DIR/config"
sed -i.bak 's/localhost/kubernetes.docker.internal/g' "$TEMP_KUBE_DIR/config"

echo "✅ Created Docker-compatible kubeconfig at $TEMP_KUBE_DIR/config"

# Show what was changed
echo "🔍 Configuration changes:"
diff "${HOME}/.kube/config" "$TEMP_KUBE_DIR/config" || true

echo ""
echo "📝 The container will now use this modified kubeconfig to access your cluster."
echo "   Original: https://127.0.0.1:6443"
echo "   Container: https://kubernetes.docker.internal:6443"
