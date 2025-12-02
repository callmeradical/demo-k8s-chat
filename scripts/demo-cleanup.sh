#!/bin/bash

# 🧹 K8s Chat Demo - Cleanup
# Remove the demo deployment and any secrets

set -e

echo "🧹 K8s Chat Demo - Cleanup"
echo "=========================="
echo ""

echo "🗑️  Removing k8s-chat demo deployment..."

# Uninstall helm release
helm uninstall k8s-chat-demo -n demo 2>/dev/null && echo "✅ Helm release removed" || echo "⚠️  No helm release found"

# Remove any leftover secrets
kubectl delete secret k8s-chat-demo-anthropic -n demo 2>/dev/null && echo "✅ Secret removed" || echo "⚠️  No secret found"

# Remove namespace if empty
REMAINING_RESOURCES=$(kubectl get all -n demo 2>/dev/null | grep -v "No resources found" | wc -l || echo "0")
if [ "$REMAINING_RESOURCES" -eq 0 ]; then
    kubectl delete namespace demo 2>/dev/null && echo "✅ Empty namespace removed" || echo "⚠️  Namespace not found"
else
    echo "ℹ️  Keeping namespace 'demo' (has other resources)"
fi

echo ""
echo "✅ Cleanup complete!"
echo "🔐 Your API key has been removed from the cluster."
