#!/bin/bash

# 🔑 K8s Chat Demo - Runtime API Key Injection
# Use this script in your codespace to inject API key without storing it

set -e

echo "🔑 K8s Chat Demo - API Key Injection"
echo "===================================="
echo ""

# Check if API key is provided
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ ANTHROPIC_API_KEY not found in environment"
    echo ""
    echo "Please set your API key first:"
    echo "  export ANTHROPIC_API_KEY='your-api-key-here'"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ ANTHROPIC_API_KEY found in environment"
echo ""

# Check if deployment exists
DEPLOYMENT_EXISTS=$(kubectl get deployment k8s-chat-demo -n demo 2>/dev/null || echo "")

if [ -z "$DEPLOYMENT_EXISTS" ]; then
    echo "🚀 Deploying k8s-chat for the first time..."

    # Deploy without API key first
    helm install k8s-chat-demo ./helm/k8s-chat \
        --namespace demo --create-namespace \
        --wait

    echo "✅ Initial deployment complete"
    echo ""
fi

echo "🔧 Injecting API key into running deployment..."

# Method 1: Use helm upgrade (cleanest)
helm upgrade k8s-chat-demo ./helm/k8s-chat \
    --set secrets.anthropic.apiKey="$ANTHROPIC_API_KEY" \
    --namespace demo \
    --wait

echo ""
echo "✅ API key injected successfully!"
echo ""

# Get service info
NODE_PORT=$(kubectl get svc k8s-chat-demo -n demo -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")

echo "🌐 Access your k8s-chat demo:"
if [ -n "$NODE_PORT" ] && [ -n "$NODE_IP" ]; then
    echo "  External: http://$NODE_IP:$NODE_PORT"
fi
echo "  Port-forward: kubectl port-forward svc/k8s-chat-demo 3000:3000 -n demo"
echo "  Then visit: http://localhost:3000"
echo ""

echo "📋 Useful commands:"
echo "  kubectl get pods -n demo                    # Check status"
echo "  kubectl logs -l app.kubernetes.io/name=k8s-chat -n demo -f  # View logs"
echo "  helm uninstall k8s-chat-demo -n demo       # Clean up"
echo ""

echo "🔐 Security Note:"
echo "  Your API key is now temporarily stored in the cluster secret."
echo "  It will be removed when you run: helm uninstall k8s-chat-demo -n demo"
echo ""

echo "🎉 Demo ready! Start chatting with your Kubernetes cluster!"
