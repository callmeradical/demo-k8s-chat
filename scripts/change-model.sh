#!/bin/bash

# Dynamic Goose Model Configuration Script
# Allows changing the model without rebuilding the container

set -e

echo "🔧 Dynamic Goose Model Configuration"
echo "===================================="

# Available models
echo ""
echo "📋 Available Models:"
echo "   1) claude-haiku-3-0           (Fastest, Highest Rate Limits, Cheapest)"
echo "   2) claude-sonnet-3-5-latest   (Balanced Performance)"
echo "   3) claude-sonnet-3-7-latest   (Better Performance, Good Rate Limits)"
echo "   4) claude-sonnet-4-0          (Best Performance, Lower Rate Limits)"
echo "   5) gpt-4o-mini               (OpenAI - Different Provider)"
echo "   6) custom                    (Enter your own model name)"
echo ""

# Current model
CURRENT_MODEL=$(grep "GOOSE_MODEL:" goose-config.yaml | sed 's/.*: //')
echo "🎯 Current Model: $CURRENT_MODEL"
echo ""

# Get user choice
read -p "Select model (1-6) or press Enter to keep current: " choice

case $choice in
    1)
        NEW_MODEL="claude-haiku-3-0"
        PROVIDER="anthropic"
        ;;
    2)
        NEW_MODEL="claude-sonnet-3-5-latest"
        PROVIDER="anthropic"
        ;;
    3)
        NEW_MODEL="claude-sonnet-3-7-latest"
        PROVIDER="anthropic"
        ;;
    4)
        NEW_MODEL="claude-sonnet-4-0"
        PROVIDER="anthropic"
        ;;
    5)
        NEW_MODEL="gpt-4o-mini"
        PROVIDER="openai"
        echo "⚠️  Note: You'll need an OpenAI API key (OPENAI_API_KEY) instead of Anthropic"
        ;;
    6)
        read -p "Enter custom model name: " NEW_MODEL
        read -p "Enter provider (anthropic/openai): " PROVIDER
        ;;
    "")
        echo "✅ Keeping current model: $CURRENT_MODEL"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "🔄 Updating configuration..."

# Update the model in goose-config.yaml
sed -i.bak "s/GOOSE_MODEL: .*/GOOSE_MODEL: $NEW_MODEL/" goose-config.yaml
sed -i.bak "s/GOOSE_PROVIDER: .*/GOOSE_PROVIDER: $PROVIDER/" goose-config.yaml

# Update the host if switching providers
if [ "$PROVIDER" = "openai" ]; then
    sed -i.bak "s/ANTHROPIC_HOST: .*/OPENAI_HOST: https:\/\/api.openai.com/" goose-config.yaml
else
    sed -i.bak "s/OPENAI_HOST: .*/ANTHROPIC_HOST: https:\/\/api.anthropic.com/" goose-config.yaml
fi

echo "✅ Configuration updated!"
echo "   Model: $NEW_MODEL"
echo "   Provider: $PROVIDER"
echo ""

# Check if container is running
if docker compose -f docker-compose.goose.yml ps goose-web | grep -q "Up"; then
    echo "🔄 Restarting Goose container to apply changes..."
    docker compose -f docker-compose.goose.yml restart goose-web

    echo ""
    echo "⏳ Waiting for Goose to start..."
    sleep 5

    echo "✅ Model changed successfully!"
    echo "🌐 Goose Web Interface: http://localhost:3000"
    echo ""
    echo "💡 The new model ($NEW_MODEL) is now active!"

    if [ "$PROVIDER" = "openai" ]; then
        echo ""
        echo "⚠️  IMPORTANT: Make sure you have OPENAI_API_KEY set:"
        echo "   export OPENAI_API_KEY='your-openai-api-key-here'"
    fi
else
    echo "ℹ️  Container is not running. Start with:"
    echo "   ./run-goose.sh"
    echo ""
    echo "💡 The new model ($NEW_MODEL) will be used when you start Goose."
fi

echo ""
echo "🦢 Happy chatting with your new model!"
