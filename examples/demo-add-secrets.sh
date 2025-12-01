#!/bin/bash
# Demo: Adding Secrets to Running k8s-chat Application with ArgoCD

set -e

echo "🚀 Demo: Adding Secrets to k8s-chat with ArgoCD"
echo "================================================"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if k8s-chat is running
echo -e "${BLUE}📊 Checking current k8s-chat deployment...${NC}"
if kubectl get deployment k8s-chat-demo -n demo >/dev/null 2>&1; then
    echo -e "${GREEN}✅ k8s-chat-demo deployment found${NC}"
    kubectl get pods -l app.kubernetes.io/name=k8s-chat -n demo
else
    echo -e "${RED}❌ k8s-chat-demo deployment not found. Please deploy first.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔐 Step 1: Creating a new database secret...${NC}"

# Create the secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: k8s-chat-demo-database
  namespace: demo
  labels:
    app.kubernetes.io/name: k8s-chat
    app.kubernetes.io/instance: k8s-chat-demo
    app.kubernetes.io/managed-by: manual
    demo: "secret-addition"
type: Opaque
data:
  database-url: $(echo -n "postgresql://myuser:secretpass@localhost:5432/k8schat" | base64 -w 0)
  username: $(echo -n "k8s_chat_user" | base64 -w 0)
  password: $(echo -n "demo_secret_password_123" | base64 -w 0)
  redis-url: $(echo -n "redis://localhost:6379" | base64 -w 0)
EOF

echo -e "${GREEN}✅ Secret created successfully${NC}"
kubectl get secret k8s-chat-demo-database -n demo

echo ""
echo -e "${BLUE}⚙️ Step 2: Current environment variables in the pod...${NC}"
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=k8s-chat -n demo -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD_NAME"
kubectl exec $POD_NAME -n demo -- env | grep -E "(ANTHROPIC|GOOSE)" | head -5

echo ""
echo -e "${BLUE}🔄 Step 3: Update ArgoCD Application to use the new secret...${NC}"
echo "You would now update your ArgoCD Application with:"
echo ""
cat <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k8s-chat-demo
spec:
  source:
    helm:
      values: |
        secrets:
          anthropic:
            create: true
            apiKey: "your-anthropic-key"

          additional:
            - envName: "DATABASE_URL"
              secretName: "k8s-chat-demo-database"
              secretKey: "database-url"

            - envName: "DB_USERNAME"
              secretName: "k8s-chat-demo-database"
              secretKey: "username"

            - envName: "DB_PASSWORD"
              secretName: "k8s-chat-demo-database"
              secretKey: "password"

            - envName: "REDIS_URL"
              secretName: "k8s-chat-demo-database"
              secretKey: "redis-url"
EOF

echo ""
echo -e "${YELLOW}🔄 Step 4: Simulating ArgoCD sync...${NC}"
echo "In a real scenario, ArgoCD would detect the change and redeploy."
echo "For demo purposes, we'll update the deployment manually:"

# Patch the deployment to add the new environment variables
kubectl patch deployment k8s-chat-demo -n demo --type='merge' -p='{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "k8s-chat",
          "env": [
            {
              "name": "ANTHROPIC_API_KEY",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "k8s-chat-demo-anthropic",
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
              "name": "KUBECONFIG",
              "value": "/home/goose/.kube/config"
            },
            {
              "name": "DATABASE_URL",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "k8s-chat-demo-database",
                  "key": "database-url"
                }
              }
            },
            {
              "name": "DB_USERNAME",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "k8s-chat-demo-database",
                  "key": "username"
                }
              }
            },
            {
              "name": "DB_PASSWORD",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "k8s-chat-demo-database",
                  "key": "password"
                }
              }
            },
            {
              "name": "REDIS_URL",
              "valueFrom": {
                "secretKeyRef": {
                  "name": "k8s-chat-demo-database",
                  "key": "redis-url"
                }
              }
            }
          ]
        }]
      }
    }
  }
}'

echo -e "${GREEN}✅ Deployment updated${NC}"

echo ""
echo -e "${BLUE}⏳ Step 5: Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/k8s-chat-demo -n demo

echo ""
echo -e "${BLUE}🔍 Step 6: Verifying the new environment variables...${NC}"
NEW_POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=k8s-chat -n demo -o jsonpath='{.items[0].metadata.name}')
echo "New Pod: $NEW_POD_NAME"

echo ""
echo "Database-related environment variables:"
kubectl exec $NEW_POD_NAME -n demo -- env | grep -E "(DATABASE|DB_|REDIS)" || echo "Environment variables not yet available"

echo ""
echo -e "${BLUE}🧪 Step 7: Testing secret access...${NC}"
echo "Testing if the pod can read the secret values:"
kubectl exec $NEW_POD_NAME -n demo -- sh -c 'echo "DATABASE_URL length: ${#DATABASE_URL}"'
kubectl exec $NEW_POD_NAME -n demo -- sh -c 'echo "DB_USERNAME: $DB_USERNAME"'
kubectl exec $NEW_POD_NAME -n demo -- sh -c 'echo "Redis URL set: $([ -n "$REDIS_URL" ] && echo "Yes" || echo "No")"'

echo ""
echo -e "${GREEN}🎉 Demo Complete!${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "1. ✅ Created a new secret with database credentials"
echo "2. ✅ Updated the deployment to reference the secret"
echo "3. ✅ Pod now has access to the database credentials as environment variables"
echo "4. ✅ Application can now use these secrets for database connections"
echo ""
echo -e "${BLUE}💡 In a real ArgoCD scenario:${NC}"
echo "- You'd update the Application manifest in Git"
echo "- ArgoCD would automatically detect and sync the changes"
echo "- The deployment would be updated with zero-downtime rolling update"
echo "- ArgoCD would show the sync status and any issues"

echo ""
echo -e "${YELLOW}🧹 Cleanup (optional):${NC}"
echo "To remove the demo secret: kubectl delete secret k8s-chat-demo-database -n demo"
