#!/bin/bash

# 🚀 GitHub Codespaces Setup for Real Goose K8s Chat Demo
# This script sets up a complete demo environment in Codespaces

set -e

echo "🦢 Setting up Real Goose K8s Chat Demo in GitHub Codespaces"
echo "=========================================================="

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${BLUE}🔧 $1${NC}"
}

print_step "Installing additional dependencies"
sudo apt-get update
sudo apt-get install -y jq tree

print_step "Starting Minikube cluster"
minikube start --driver=docker --cpus=2 --memory=4g --disk-size=20g
minikube addons enable dashboard
minikube addons enable metrics-server

print_step "Setting up kubectl context"
kubectl config use-context minikube

print_step "Creating demo namespace and resources"
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

# Create some demo workloads for Goose to interact with
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-nginx
  namespace: demo
  labels:
    app: demo-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-nginx
  template:
    metadata:
      labels:
        app: demo-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: demo-nginx-service
  namespace: demo
spec:
  selector:
    app: demo-nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

print_step "Setting up demo scripts"
# Create quick demo commands
cat <<'EOF' > /home/vscode/demo-commands.txt
🎯 Real Goose K8s Chat - Demo Commands to Try:

Basic Commands:
- "Show me all pods in the default namespace"
- "Show me all pods in the demo namespace"
- "What deployments are running?"
- "Show me the status of all services"

Interactive Commands:
- "Scale the demo-nginx deployment to 5 replicas"
- "Create a simple busybox pod for testing"
- "Show me the logs from the nginx pods"
- "Delete the busybox pod when done testing"

Cluster Information:
- "Show me cluster information"
- "What nodes are available?"
- "Show me cluster resource usage"

Advanced:
- "Create a deployment with 3 replicas of httpd"
- "Expose that deployment as a service"
- "Show me all events in the demo namespace"
EOF

print_step "Making scripts executable"
find /workspaces -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

print_step "Starting kubectl proxy for dashboard access"
nohup kubectl proxy --port=8001 --address='0.0.0.0' --accept-hosts='^.*' > /tmp/kubectl-proxy.log 2>&1 &

print_step "Creating quick start README"
cat <<'EOF' > /home/vscode/DEMO_QUICK_START.md
# 🦢 Real Goose K8s Chat - Demo Quick Start

## 🚀 What's Ready:
- ✅ Minikube cluster running
- ✅ Kubernetes Dashboard available
- ✅ Demo workloads deployed (nginx)
- ✅ Real Goose ready to deploy

## 🎯 Quick Demo Steps:

### 1. Start Real Goose
```bash
export ANTHROPIC_API_KEY="your-key-here"
make local-start
```

### 2. Access Real Goose
- The web interface will open automatically at port 3000
- Or click the "Ports" tab and open the "Real Goose K8s Chat" port

### 3. Try These Demo Commands:
- "Show me all pods in the demo namespace"
- "Scale the demo-nginx deployment to 5 replicas"
- "Create a simple busybox pod for testing"
- "Show me cluster information"

### 4. Access Kubernetes Dashboard:
- Open port 8001 to access kubectl proxy
- Navigate to: `/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/`

## 🔧 Useful Commands:
```bash
make info          # Check environment status
make k8s-status    # Check if deployed to cluster
kubectl get pods   # See all pods
minikube status    # Check cluster status
```

## 📋 Demo Script Available:
Check `/home/vscode/demo-commands.txt` for suggested commands to try with Goose!
EOF

echo -e "\n${GREEN}✅ GitHub Codespaces demo environment ready!${NC}"
echo -e "${YELLOW}📖 Check /home/vscode/DEMO_QUICK_START.md for next steps${NC}"
echo -e "${YELLOW}📋 Demo commands available in /home/vscode/demo-commands.txt${NC}"
echo ""
echo -e "${BLUE}🎯 To start the demo:${NC}"
echo "1. Set your API key: export ANTHROPIC_API_KEY='your-key'"
echo "2. Run: make local-start"
echo "3. Open port 3000 to access Real Goose"
echo "4. Try the demo commands and interact with your Kubernetes cluster!"
