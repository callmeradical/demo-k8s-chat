#!/bin/bash

# 🔊 Toggle Verbose Logging for k8s-chat
# This script allows you to enable/disable verbose logging on running deployments

set -e

echo "🔊 k8s-chat Verbose Logging Control"
echo "==================================="
echo ""

# Get deployment and namespace info
DEPLOYMENT_NAME=${1:-"k8s-chat"}
NAMESPACE=${2:-"k8s-chat"}
ACTION=${3:-"enable"}  # enable, disable, or status

# Check if deployment exists
if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "❌ Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'"
    echo ""
    echo "Available deployments:"
    kubectl get deployments -A | grep k8s-chat || echo "No k8s-chat deployments found"
    echo ""
    echo "Usage: $0 [deployment-name] [namespace] [enable|disable|status]"
    echo "Example: $0 k8s-chat-demo demo enable"
    exit 1
fi

case "$ACTION" in
    "enable")
        echo "🔊 Enabling verbose logging..."
        kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type='json' -p='[
          {
            "op": "replace",
            "path": "/spec/template/spec/containers/0/env",
            "value": [
              {
                "name": "ANTHROPIC_API_KEY",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "'"$DEPLOYMENT_NAME"'-anthropic",
                    "key": "api-key"
                  }
                }
              },
              {
                "name": "GOOSE_CONFIG_DIR",
                "value": "/home/goose/.config/goose"
              },
              {
                "name": "GOOSE_DATA_DIR",
                "value": "/home/goose/.local/share/goose"
              },
              {
                "name": "RUST_LOG",
                "value": "debug"
              },
              {
                "name": "GOOSE_LOG_LEVEL",
                "value": "debug"
              }
            ]
          }
        ]'

        echo "✅ Verbose logging enabled!"
        ;;

    "disable")
        echo "🔇 Disabling verbose logging..."
        kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type='json' -p='[
          {
            "op": "replace",
            "path": "/spec/template/spec/containers/0/env",
            "value": [
              {
                "name": "ANTHROPIC_API_KEY",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "'"$DEPLOYMENT_NAME"'-anthropic",
                    "key": "api-key"
                  }
                }
              },
              {
                "name": "GOOSE_CONFIG_DIR",
                "value": "/home/goose/.config/goose"
              },
              {
                "name": "GOOSE_DATA_DIR",
                "value": "/home/goose/.local/share/goose"
              },
              {
                "name": "RUST_LOG",
                "value": "info"
              },
              {
                "name": "GOOSE_LOG_LEVEL",
                "value": "info"
              }
            ]
          }
        ]'

        echo "✅ Verbose logging disabled!"
        ;;

    "status")
        echo "📋 Current logging configuration:"
        kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="RUST_LOG")].value}' | xargs -I{} echo "  RUST_LOG: {}"
        kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="GOOSE_LOG_LEVEL")].value}' | xargs -I{} echo "  GOOSE_LOG_LEVEL: {}"
        echo ""
        ;;

    *)
        echo "❌ Invalid action: $ACTION"
        echo "Usage: $0 [deployment-name] [namespace] [enable|disable|status]"
        exit 1
        ;;
esac

if [ "$ACTION" != "status" ]; then
    echo ""
    echo "⏳ Waiting for rollout to complete..."
    kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=60s

    echo ""
    echo "📋 View logs with:"
    echo "   kubectl logs -l app.kubernetes.io/name=k8s-chat -n $NAMESPACE -f"
fi
