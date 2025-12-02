#!/bin/bash

# 🔑 Quick API Key Patch for Running k8s-chat Deployment
# Use this for fast API key injection into existing deployment

set -e

echo "🔑 Quick API Key Injection"
echo "=========================="
echo ""

# Check if API key is provided
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ ANTHROPIC_API_KEY not found in environment"
    echo ""
    echo "Please set your API key first:"
    echo "  export ANTHROPIC_API_KEY='your-api-key-here'"
    echo ""
    exit 1
fi

# Get deployment and namespace info
DEPLOYMENT_NAME=${1:-"k8s-chat"}
NAMESPACE=${2:-"k8s-chat"}

echo "🔍 Looking for deployment '$DEPLOYMENT_NAME' in namespace '$NAMESPACE'..."

# Check if deployment exists
if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "❌ Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'"
    echo ""
    echo "Available deployments:"
    kubectl get deployments -A | grep k8s-chat || echo "No k8s-chat deployments found"
    echo ""
    echo "Usage: $0 [deployment-name] [namespace]"
    echo "Example: $0 k8s-chat-demo demo"
    exit 1
fi

echo "✅ Found deployment '$DEPLOYMENT_NAME'"
echo ""

# Get current container name
CONTAINER_NAME=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].name}')

echo "🔧 Patching deployment with API key..."
echo "   Container: $CONTAINER_NAME"
echo "   Deployment: $DEPLOYMENT_NAME"
echo "   Namespace: $NAMESPACE"
echo ""

# Proper patch that adds/updates just the environment variable
kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name": "ANTHROPIC_API_KEY",
      "value": "'"$ANTHROPIC_API_KEY"'"
    }
  }
]' 2>/dev/null || \
kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/env",
    "value": [
      {
        "name": "ANTHROPIC_API_KEY",
        "value": "'"$ANTHROPIC_API_KEY"'"
      }
    ]
  }
]'

echo "✅ API key injected successfully!"
echo ""

# Wait for rollout
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=60s

echo ""
echo "🎉 Deployment updated and ready!"
echo ""

# Show access info
NODE_PORT=$(kubectl get svc "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
if [ -n "$NODE_PORT" ]; then
    echo "🌐 Access via NodePort: http://localhost:$NODE_PORT"
fi

echo "🌐 Access via port-forward:"
echo "   kubectl port-forward svc/$DEPLOYMENT_NAME 3000:3000 -n $NAMESPACE"
echo "   Then visit: http://localhost:3000"
echo ""

echo "📋 Check logs:"
echo "   kubectl logs -l app.kubernetes.io/name=k8s-chat -n $NAMESPACE -f"
