# K8s Chat - Kubernetes AI Assistant Demo
# Creates K8s secret from environment variable and launches Goose

.PHONY: help setup build run-local helm-install helm-uninstall clean

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE=\033[0;34m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

PROJECT_NAME=k8s-chat
DOCKER_IMAGE=k8s-chat
NAMESPACE=default

help: ## Show this help message
	@echo "$(BLUE)🦢 K8s Chat$(NC)"
	@echo "================"
	@echo ""
	@echo "$(YELLOW)Prerequisites:$(NC)"
	@echo "  - Set ANTHROPIC_API_KEY environment variable"
	@echo "  - kubectl configured for your cluster"
	@echo "  - helm installed (for Kubernetes deployment)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "$(YELLOW)Available commands:$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Install dependencies and setup environment
	@echo "$(BLUE)🔧 Setting up K8s Chat environment...$(NC)"
	@if [ -z "$$ANTHROPIC_API_KEY" ]; then \
		echo "$(RED)❌ ANTHROPIC_API_KEY not set$(NC)"; \
		echo "$(YELLOW)💡 Please set: export ANTHROPIC_API_KEY=\"sk-ant-...\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ ANTHROPIC_API_KEY is set$(NC)"
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)❌ kubectl not found$(NC)"; exit 1; }
	@echo "$(GREEN)✅ kubectl found$(NC)"
	@command -v helm >/dev/null 2>&1 || { echo "$(RED)❌ helm not found$(NC)"; exit 1; }
	@echo "$(GREEN)✅ helm found$(NC)"
	@./setup-and-run.sh --setup-only 2>/dev/null || echo "$(GREEN)✅ Environment ready$(NC)"

build: ## Build the Docker image
	@echo "$(BLUE)🔨 Building K8s Chat image...$(NC)"
	@docker build -t $(DOCKER_IMAGE):latest .
	@echo "$(GREEN)✅ Image built: $(DOCKER_IMAGE):latest$(NC)"

create-secret: setup ## Create Kubernetes secret from ANTHROPIC_API_KEY
	@echo "$(BLUE)🔐 Creating Kubernetes secret...$(NC)"
	@kubectl create secret generic k8s-chat-anthropic \
		--from-literal=api-key="$$ANTHROPIC_API_KEY" \
		--namespace="$(NAMESPACE)" \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "$(GREEN)✅ Secret k8s-chat-anthropic created/updated in namespace $(NAMESPACE)$(NC)"

run-local: setup ## Run locally (creates secret and launches goose)
	@echo "$(BLUE)🚀 Running K8s Chat locally...$(NC)"
	@./setup-and-run.sh

helm-install: setup build ## Deploy to Kubernetes using Helm (assumes secret already exists)
	@echo "$(BLUE)🚀 Deploying K8s Chat to Kubernetes...$(NC)"
	@echo "$(YELLOW)📦 Installing Helm chart...$(NC)"
	@echo "$(YELLOW)💡 Note: Assumes k8s-chat-anthropic secret already exists. Run 'make create-secret' first if needed.$(NC)"
	@helm upgrade --install k8s-chat ./helm/k8s-chat \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set image.repository=$(DOCKER_IMAGE) \
		--set image.tag=latest \
		--wait
	@echo "$(GREEN)✅ K8s Chat deployed successfully!$(NC)"
	@echo "$(YELLOW)🌐 Access via: kubectl port-forward svc/k8s-chat 3000:3000$(NC)"

helm-uninstall: ## Remove the Helm deployment
	@echo "$(BLUE)🗑️  Removing K8s Chat from Kubernetes...$(NC)"
	@helm uninstall k8s-chat --namespace $(NAMESPACE) || true
	@kubectl delete secret k8s-chat-anthropic --namespace $(NAMESPACE) || true
	@echo "$(GREEN)✅ K8s Chat removed$(NC)"

clean: ## Clean up local Docker images
	@echo "$(BLUE)🧹 Cleaning up...$(NC)"
	@docker rmi $(DOCKER_IMAGE):latest 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

# Quick commands for Codespaces
codespaces: ## Quick setup for GitHub Codespaces
	@echo "$(BLUE)🚀 GitHub Codespaces Quick Setup$(NC)"
	@echo "$(YELLOW)1. Set your API key: export ANTHROPIC_API_KEY=\"sk-ant-...\"$(NC)"
	@echo "$(YELLOW)2. Run: make run-local$(NC)"
	@echo "$(YELLOW)3. Or deploy to K8s: make helm-install$(NC)"
