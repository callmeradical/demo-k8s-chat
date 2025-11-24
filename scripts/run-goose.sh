#!/bin/bash

# K8s Chat with Real Goose - Container Setup Script

set -e

echo "🦢 K8s Chat with Real Goose v1.15.0 - Container Setup"
echo "=============================================="

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "⚠️  ANTHROPIC_API_KEY environment variable is not set."
    echo "Please set your Anthropic API key:"
    echo "export ANTHROPIC_API_KEY='your-api-key-here'"
    echo ""
    echo "You can also create a .env file with:"
    echo "ANTHROPIC_API_KEY=your-api-key-here"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if kubectl is available and has a valid config
if ! command -v kubectl &> /dev/null; then
    echo "⚠️  kubectl is not installed on your host system."
    echo "The container includes kubectl, but you may want it locally too."
fi

if [ ! -f "$HOME/.kube/config" ]; then
    echo "⚠️  No kubeconfig found at $HOME/.kube/config"
    echo "Kubernetes operations will only work if running inside a cluster."
else
    echo "🔧 Setting up kubeconfig for container access..."
    ./setup-kubeconfig.sh
fi

# Build and start the services
echo "🔨 Building Goose container..."
docker compose -f docker-compose.goose.yml build

echo "🚀 Starting K8s Chat with Real Goose..."
docker compose -f docker-compose.goose.yml up -d

echo ""
echo "✅ Services started successfully!"
echo ""
echo "🌐 Goose Web Interface: http://localhost:3000"
echo "📊 Redis (if needed): localhost:6379"
echo ""
echo "📋 To view logs:"
echo "   docker compose -f docker-compose.goose.yml logs -f goose-web"
echo ""
echo "🔧 To change model dynamically (no rebuild needed):"
echo "   ./change-model.sh"
echo ""
echo "🛑 To stop:"
echo "   docker compose -f docker-compose.goose.yml down"
echo ""
echo "🔧 To rebuild after changes:"
echo "   docker compose -f docker-compose.goose.yml build --no-cache"
echo ""
echo "Happy Kubernetes chatting with Real Goose! 🦢✨"
