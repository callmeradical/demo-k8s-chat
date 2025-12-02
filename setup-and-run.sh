#!/bin/bash
set -e

# K8s Chat - Simple Setup Script
# Creates Kubernetes secret from ANTHROPIC_API_KEY environment variable
# and launches Goose web interface

SETUP_ONLY=false
if [ "$1" = "--setup-only" ]; then
    SETUP_ONLY=true
fi

echo "🦢 K8s Chat - Simple Setup"
echo "=========================="

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Error: ANTHROPIC_API_KEY environment variable is not set"
    echo "💡 Please set your Anthropic API key:"
    echo "   export ANTHROPIC_API_KEY=\"sk-ant-...\""
    exit 1
fi

echo "✅ ANTHROPIC_API_KEY found"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found"
    echo "💡 Please install kubectl to manage Kubernetes resources"
    exit 1
fi

echo "✅ kubectl found"

# Check if goose is available (only if not setup-only mode)
if [ "$SETUP_ONLY" = "false" ]; then
    if ! command -v goose &> /dev/null; then
        echo "❌ Error: goose not found"
        echo "💡 Please install goose: https://github.com/block/goose#installation"
        exit 1
    fi
    echo "✅ goose found"
fi

# Get current namespace (default to 'default' if not set)
NAMESPACE=${KUBERNETES_NAMESPACE:-default}
echo "🔧 Using namespace: $NAMESPACE"

# Create or update the Kubernetes secret
SECRET_NAME="k8s-chat-anthropic"
echo "🔑 Creating/updating Kubernetes secret: $SECRET_NAME"

kubectl create secret generic $SECRET_NAME \
    --from-literal=api-key="$ANTHROPIC_API_KEY" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo "✅ Secret $SECRET_NAME created/updated successfully"
else
    echo "❌ Failed to create secret"
    exit 1
fi

# Exit early if setup-only mode
if [ "$SETUP_ONLY" = "true" ]; then
    echo "✅ Setup complete (setup-only mode)"
    exit 0
fi

# Configure goose with Anthropic provider
echo "🔧 Configuring goose..."
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"

# Create goose config if it doesn't exist
mkdir -p ~/.config/goose
cat > ~/.config/goose/config.yaml << EOF
providers:
  anthropic:
    type: anthropic
default_provider: anthropic
EOF

echo "✅ Goose configuration created"

# Launch goose web interface
echo "🚀 Launching Goose web interface..."
echo "📝 Access at: http://localhost:3000"
echo "🛑 Press Ctrl+C to stop"
echo ""

# Start goose web server
goose web --host 0.0.0.0 --port 3000
