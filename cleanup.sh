#!/bin/bash

# Goose Kubernetes Demo - Cleanup Script
set -e

echo "🧹 Cleaning up Goose K8s Demo"
echo "================================"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

echo "🗑️  Removing Helm release..."

# Uninstall the Helm release
helm uninstall goose-demo -n goose --ignore-not-found

echo "🗑️  Removing cluster-level resources..."

# Delete cluster-level resources (ClusterRole and ClusterRoleBinding)
kubectl delete clusterrole goose-demo-goose-k8s-demo-cluster-role --ignore-not-found=true
kubectl delete clusterrolebinding goose-demo-goose-k8s-demo-cluster-role-binding --ignore-not-found=true

echo "✅ Cleanup completed successfully!"
echo ""
echo "📝 Note: The 'goose' namespace and 'anthropic-api-key' secret were preserved."
echo "   To remove them as well:"
echo "   kubectl delete secret anthropic-api-key -n goose"
echo "   kubectl delete namespace goose"
echo ""
echo "📦 To also remove the Docker image:"
echo "   docker rmi goose-k8s-demo:latest"
