# Remote Kubernetes Cluster Setup Guide

This guide covers deploying k8s-chat to remote Kubernetes clusters (EKS, GKE, AKS, etc.) instead of local development clusters.

## Overview

The k8s-chat deployment scripts now automatically detect cluster types and handle:

- **Local clusters**: Docker Desktop, Minikube, Kind
- **Remote clusters**: EKS, GKE, AKS, and other cloud providers
- **Kubeconfig management**: Automatic handling of different authentication methods
- **Container registry**: Automatic image pushing for remote deployments

## Quick Start for Remote Clusters

1. **Setup your cloud cluster and authenticate**
2. **Set registry for image storage**
3. **Deploy with automatic detection**

```bash
# Example for EKS
export REGISTRY=your-account.dkr.ecr.us-west-2.amazonaws.com
export ANTHROPIC_API_KEY='your-api-key'
make k8s-deploy
```

## Cloud Provider Setup

### AWS EKS Setup

#### Prerequisites
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Configure AWS credentials
aws configure
```

#### Create EKS Cluster
```bash
# Using eksctl (recommended)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create cluster
eksctl create cluster \
    --name k8s-chat-cluster \
    --region us-west-2 \
    --nodes 2 \
    --node-type t3.medium

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name k8s-chat-cluster
```

#### Setup ECR Repository
```bash
# Create ECR repository
aws ecr create-repository --repository-name demo-k8s-chat-goose-web --region us-west-2

# Get login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com

# Set registry environment variable
export REGISTRY=<account-id>.dkr.ecr.us-west-2.amazonaws.com
```

#### Deploy to EKS
```bash
export ANTHROPIC_API_KEY='your-api-key'
export REGISTRY=<account-id>.dkr.ecr.us-west-2.amazonaws.com
make k8s-deploy
```

### Google GKE Setup

#### Prerequisites
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

#### Create GKE Cluster
```bash
# Create cluster
gcloud container clusters create k8s-chat-cluster \
    --zone us-central1-a \
    --num-nodes 2 \
    --machine-type e2-medium

# Get credentials
gcloud container clusters get-credentials k8s-chat-cluster --zone us-central1-a
```

#### Setup Container Registry
```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Set registry environment variable
export REGISTRY=gcr.io/YOUR_PROJECT_ID
```

#### Deploy to GKE
```bash
export ANTHROPIC_API_KEY='your-api-key'
export REGISTRY=gcr.io/YOUR_PROJECT_ID
make k8s-deploy
```

### Azure AKS Setup

#### Prerequisites
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login
```

#### Create AKS Cluster
```bash
# Create resource group
az group create --name k8s-chat-rg --location eastus

# Create AKS cluster
az aks create \
    --resource-group k8s-chat-rg \
    --name k8s-chat-cluster \
    --node-count 2 \
    --node-vm-size Standard_B2s \
    --enable-addons monitoring \
    --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group k8s-chat-rg --name k8s-chat-cluster
```

#### Setup Azure Container Registry
```bash
# Create ACR
az acr create --resource-group k8s-chat-rg --name k8schatregistry --sku Basic

# Login to ACR
az acr login --name k8schatregistry

# Attach ACR to AKS
az aks update -n k8s-chat-cluster -g k8s-chat-rg --attach-acr k8schatregistry

# Set registry environment variable
export REGISTRY=k8schatregistry.azurecr.io
```

#### Deploy to AKS
```bash
export ANTHROPIC_API_KEY='your-api-key'
export REGISTRY=k8schatregistry.azurecr.io
make k8s-deploy
```

## Manual Registry Push (Alternative)

If automatic registry detection doesn't work, you can manually push the image:

```bash
# Build and tag
docker build -f Dockerfile.goose -t demo-k8s-chat-goose-web:latest .
docker tag demo-k8s-chat-goose-web:latest $REGISTRY/demo-k8s-chat-goose-web:latest

# Push to registry
docker push $REGISTRY/demo-k8s-chat-goose-web:latest

# Deploy with registry image
make k8s-deploy-registry
```

## Troubleshooting

### Authentication Issues

**EKS Token Expiry**
```bash
# Refresh AWS credentials
aws sts get-caller-identity
aws eks update-kubeconfig --region us-west-2 --name k8s-chat-cluster
```

**GKE Token Expiry**
```bash
# Refresh gcloud credentials
gcloud auth application-default login
gcloud container clusters get-credentials k8s-chat-cluster --zone us-central1-a
```

**AKS Token Expiry**
```bash
# Refresh Azure credentials
az login
az aks get-credentials --resource-group k8s-chat-rg --name k8s-chat-cluster --overwrite-existing
```

### Network Connectivity

**Check cluster connectivity:**
```bash
kubectl cluster-info
kubectl get nodes
```

**Check kubeconfig setup:**
```bash
make setup-kubeconfig
```

### Image Pull Issues

**Check image exists in registry:**
```bash
# EKS/ECR
aws ecr describe-images --repository-name demo-k8s-chat-goose-web

# GKE/GCR
gcloud container images list --repository=gcr.io/YOUR_PROJECT_ID

# AKS/ACR
az acr repository list --name k8schatregistry
```

**Check pod events:**
```bash
kubectl get events --sort-by='.lastTimestamp'
kubectl describe pod -l app.kubernetes.io/name=k8s-chat
```

### Service Access Issues

**For cloud load balancer:**
```bash
# Change service type to LoadBalancer
helm upgrade k8s-chat ./helm/k8s-chat \
    --set service.type=LoadBalancer \
    --set secrets.anthropic.apiKey="$ANTHROPIC_API_KEY"
```

**For ingress setup:**
```bash
# Enable ingress in values
helm upgrade k8s-chat ./helm/k8s-chat \
    --set ingress.enabled=true \
    --set ingress.hosts[0].host=k8s-chat.yourdomain.com \
    --set secrets.anthropic.apiKey="$ANTHROPIC_API_KEY"
```

## Security Best Practices

### Use Service Accounts

Create a dedicated service account for production deployments:

```bash
# Create service account
kubectl create serviceaccount k8s-chat-sa

# Create role binding (adjust permissions as needed)
kubectl create clusterrolebinding k8s-chat-binding \
    --clusterrole=view \
    --serviceaccount=default:k8s-chat-sa

# Update deployment to use service account
helm upgrade k8s-chat ./helm/k8s-chat \
    --set serviceAccount.name=k8s-chat-sa \
    --set secrets.anthropic.apiKey="$ANTHROPIC_API_KEY"
```

### Use External Secrets

For production, use External Secrets Operator instead of plain secrets:

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# Deploy with external secrets enabled
helm upgrade k8s-chat ./helm/k8s-chat \
    --set externalSecrets.enabled=true \
    --set externalSecrets.secretStore.name=aws-secretsmanager \
    --set externalSecrets.remoteRef.key=k8s-chat/anthropic-key
```

## Monitoring and Logging

### Check deployment status
```bash
make k8s-status
```

### View logs
```bash
make k8s-logs
```

### Access metrics (if monitoring is enabled)
```bash
kubectl port-forward svc/prometheus-server 9090:80
# Access http://localhost:9090
```

## Cleanup

### Remove deployment
```bash
make k8s-clean
```

### Delete cluster resources
```bash
# EKS
eksctl delete cluster --name k8s-chat-cluster --region us-west-2

# GKE
gcloud container clusters delete k8s-chat-cluster --zone us-central1-a

# AKS
az group delete --name k8s-chat-rg
```
