#!/bin/bash

# 🔐 Create Kubernetes Secret for k8s-chat API Key
# This creates the secret that the deployment expects

set -e

echo "🔐 K8s Secret Creation for k8s-chat"
echo "===================================="
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

# Determine the secret name the deployment expects
SECRET_NAME="${DEPLOYMENT_NAME}-anthropic"

echo "🔧 Creating/updating secret '$SECRET_NAME'..."

# Create the secret
kubectl create secret generic "$SECRET_NAME" \
    --from-literal=api-key="$ANTHROPIC_API_KEY" \
    --namespace "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret '$SECRET_NAME' created/updated!"
echo ""

# Check if deployment is already using the secret
CURRENT_SECRET=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="ANTHROPIC_API_KEY")].valueFrom.secretKeyRef.name}' 2>/dev/null || echo "")

if [ "$CURRENT_SECRET" = "$SECRET_NAME" ]; then
    echo "✅ Deployment already configured to use secret '$SECRET_NAME'"
    echo "🔄 Restarting deployment to pick up new secret value..."
    kubectl rollout restart deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
else
    echo "🔧 Updating deployment to use secret reference..."

    # Patch deployment to use secretKeyRef instead of direct value
    kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type='json' -p='[
      {
        "op": "replace",
        "path": "/spec/template/spec/containers/0/env",
        "value": [
          {
            "name": "ANTHROPIC_API_KEY",
            "valueFrom": {
              "secretKeyRef": {
                "name": "'"$SECRET_NAME"'",
                "key": "api-key"
              }
            }
          }
        ]
      }
    ]'

    echo "✅ Deployment updated to use secret reference!"
fi

echo ""

# Wait for rollout
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=60s

echo ""
echo "🎉 Deployment updated and ready!"
echo ""

# Show secret info
echo "🔐 Secret Information:"
echo "   Name: $SECRET_NAME"
echo "   Namespace: $NAMESPACE"
echo "   Key: api-key"
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

echo "📋 Verify secret is working:"
echo "   kubectl logs -l app.kubernetes.io/name=k8s-chat -n $NAMESPACE -f"
echo ""

echo "🧹 To remove the secret later:"
echo "   kubectl delete secret $SECRET_NAME -n $NAMESPACE"
