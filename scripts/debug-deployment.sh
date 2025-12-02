#!/bin/bash

# 🔍 Debug k8s-chat Deployment Issues
# This script helps diagnose why goose might not be responding

set -e

echo "🔍 k8s-chat Deployment Debugging"
echo "================================="
echo ""

# Get deployment and namespace info
DEPLOYMENT_NAME=${1:-"k8s-chat"}
NAMESPACE=${2:-"k8s-chat"}

echo "🔍 Checking deployment '$DEPLOYMENT_NAME' in namespace '$NAMESPACE'..."
echo ""

# Check if deployment exists
if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "❌ Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'"
    echo ""
    echo "Available deployments:"
    kubectl get deployments -A | grep k8s-chat || echo "No k8s-chat deployments found"
    exit 1
fi

echo "📊 Deployment Status:"
kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"
echo ""

echo "📊 Pod Status:"
kubectl get pods -l app.kubernetes.io/name=k8s-chat -n "$NAMESPACE"
echo ""

# Get pod name
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=k8s-chat -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    echo "❌ No pods found for this deployment"
    exit 1
fi

echo "🔍 Pod Details:"
kubectl describe pod "$POD_NAME" -n "$NAMESPACE"
echo ""

echo "📋 Pod Logs (last 50 lines):"
kubectl logs "$POD_NAME" -n "$NAMESPACE" --tail=50
echo ""

echo "🔐 Environment Variables:"
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- env | grep -E "(ANTHROPIC|GOOSE|KUBE)" || echo "No relevant env vars found"
echo ""

echo "🔧 kubectl in container:"
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- which kubectl || echo "kubectl not found in container"
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- kubectl version --client --short 2>/dev/null || echo "kubectl not working"
echo ""

echo "🌐 Service Account Token:"
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/ || echo "Service account token not mounted"
echo ""

echo "🔍 Kubernetes API Access Test:"
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- kubectl get pods --v=1 2>&1 || echo "Cannot access Kubernetes API"
echo ""

echo "🌐 Network Connectivity:"
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- curl -I http://localhost:3000 2>/dev/null || echo "Web interface not responding"
echo ""

echo "📁 Goose Configuration:"
kubectl exec "$POD_NAME" -n "$NAMESPACE" -- ls -la /home/goose/.config/goose/ 2>/dev/null || echo "Goose config directory not found"
echo ""

echo "⚙️  ConfigMap Content:"
kubectl get configmap "${DEPLOYMENT_NAME}-config" -n "$NAMESPACE" -o yaml 2>/dev/null || echo "No configmap found"
echo ""

echo "🔐 Secret Status:"
kubectl get secret "${DEPLOYMENT_NAME}-anthropic" -n "$NAMESPACE" 2>/dev/null || echo "No Anthropic secret found"
echo ""

echo "🔍 Service Information:"
kubectl get svc "$DEPLOYMENT_NAME" -n "$NAMESPACE" 2>/dev/null || echo "No service found"
echo ""

echo "📋 Events (last 10):"
kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
echo ""

echo "💡 Troubleshooting Tips:"
echo "========================"
echo ""
echo "1. Check if API key secret exists and has correct name:"
echo "   kubectl get secret ${DEPLOYMENT_NAME}-anthropic -n $NAMESPACE -o yaml"
echo ""
echo "2. Restart deployment to pick up changes:"
echo "   kubectl rollout restart deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
echo ""
echo "3. Follow logs in real-time:"
echo "   kubectl logs -f $POD_NAME -n $NAMESPACE"
echo ""
echo "4. Port-forward to test locally:"
echo "   kubectl port-forward svc/$DEPLOYMENT_NAME 3000:3000 -n $NAMESPACE"
echo ""
echo "5. Exec into pod for debugging:"
echo "   kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/bash"
