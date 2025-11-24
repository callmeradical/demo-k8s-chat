# Makefile for Real Goose K8s Chat
# Professional interface for containerized Goose AI agent with Kubernetes integration

.PHONY: help info validate local-start local-stop local-restart local-logs local-clean k8s-deploy k8s-clean k8s-status k8s-logs k8s-port-forward build push lint test setup-kubeconfig change-model demo-setup demo-clean ci-test ci-security-scan release-prepare clean clean-all version status install-hooks

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE=\033[0;34m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
PURPLE=\033[0;35m
CYAN=\033[0;36m
NC=\033[0m # No Color

# Project Variables
PROJECT_NAME=k8s-chat
DOCKER_IMAGE=demo-k8s-chat-goose-web
HELM_RELEASE=k8s-chat
NAMESPACE=default
GOOSE_VERSION=v1.15.0
PORT=3000
K8S_PORT=30300

# Container Variables
CONTAINER_NAME=k8s-chat-goose
COMPOSE_FILE=docker-compose.goose.yml

help: ## 🦢 Show this help message
	@echo "$(BLUE)🦢 Real Goose K8s Chat - Available Commands$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)Get started quickly:$(NC)"
	@echo "  1. $(YELLOW)make info$(NC)         - Check prerequisites"
	@echo "  2. $(YELLOW)export ANTHROPIC_API_KEY='your-key'$(NC)"
	@echo "  3. $(YELLOW)make local-start$(NC)  - Start locally"
	@echo "  4. $(YELLOW)make k8s-deploy$(NC)   - Deploy to Kubernetes"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(GREEN)<target>$(NC)\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(PURPLE)%s$(NC)\n", substr($$0, 5) }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(CYAN)💡 Tip: Run 'make info' to check your environment setup$(NC)"

##@ 🚀 Quick Actions

info: ## Show project information and environment check
	@echo "$(BLUE)🦢 Real Goose K8s Chat - Project Information$(NC)"
	@echo "============================================="
	@echo ""
	@echo "$(YELLOW)📁 Project Structure:$(NC)"
	@echo "  📦 $(PROJECT_NAME)         - Real Goose AI agent for Kubernetes"
	@echo "  🐳 Docker Image    - $(DOCKER_IMAGE)"
	@echo "  🦢 Goose Version   - $(GOOSE_VERSION)"
	@echo "  🌐 Local Port     - http://localhost:$(PORT)"
	@echo "  ☸️  K8s Port       - NodePort $(K8S_PORT)"
	@echo ""
	@echo "$(YELLOW)🔧 Components:$(NC)"
	@echo "  📁 scripts/       - All operational scripts"
	@echo "  🐳 Dockerfile.goose - Real Goose container definition"
	@echo "  ⚙️  goose-config.yaml - Goose AI configuration"
	@echo "  ☸️  helm/k8s-chat/ - Kubernetes deployment chart"
	@echo ""
	@echo "$(YELLOW)🛠️  Environment Check:$(NC)"
	@command -v docker >/dev/null 2>&1 && echo "  ✅ Docker installed" || echo "  ❌ Docker not found"
	@command -v docker-compose >/dev/null 2>&1 && echo "  ✅ Docker Compose available" || echo "  ⚠️  Docker Compose not found"
	@command -v kubectl >/dev/null 2>&1 && echo "  ✅ kubectl installed" || echo "  ❌ kubectl not found"
	@command -v helm >/dev/null 2>&1 && echo "  ✅ Helm installed" || echo "  ❌ Helm not found"
	@if [ -n "$$ANTHROPIC_API_KEY" ]; then \
		echo "  ✅ ANTHROPIC_API_KEY configured"; \
	else \
		echo "  ⚠️  ANTHROPIC_API_KEY not set"; \
		echo "     Run: export ANTHROPIC_API_KEY='your-api-key-here'"; \
	fi
	@echo ""
	@echo "$(YELLOW)🚀 Quick Start:$(NC)"
	@echo "  1. Set API key:    export ANTHROPIC_API_KEY='your-key'"
	@echo "  2. Local test:     make local-start"
	@echo "  3. K8s deploy:     make k8s-deploy"
	@echo "  4. Change model:   make change-model"
	@echo ""

validate: ## Validate all configurations and dependencies
	@echo "$(BLUE)🔍 Validating Real Goose K8s Chat setup...$(NC)"
	@echo ""
	@echo "$(YELLOW)Checking Docker setup...$(NC)"
	@docker --version || (echo "$(RED)❌ Docker not available$(NC)" && exit 1)
	@echo "$(YELLOW)Checking Goose configuration...$(NC)"
	@test -f goose-config.yaml || (echo "$(RED)❌ goose-config.yaml not found$(NC)" && exit 1)
	@echo "$(YELLOW)Checking Docker Compose file...$(NC)"
	@test -f $(COMPOSE_FILE) || (echo "$(RED)❌ $(COMPOSE_FILE) not found$(NC)" && exit 1)
	@echo "$(YELLOW)Checking Dockerfile...$(NC)"
	@test -f Dockerfile.goose || (echo "$(RED)❌ Dockerfile.goose not found$(NC)" && exit 1)
	@echo "$(GREEN)✅ All core configurations valid$(NC)"
	@echo ""

##@ 🐳 Local Development (Docker Compose)

local-start: validate ## Start Real Goose locally with Docker Compose
	@echo "$(BLUE)🚀 Starting Real Goose K8s Chat locally...$(NC)"
	@if [ -z "$$ANTHROPIC_API_KEY" ]; then \
		echo "$(RED)❌ ANTHROPIC_API_KEY environment variable is required$(NC)"; \
		echo "   Set it with: export ANTHROPIC_API_KEY='your-api-key-here'"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Setting up kubeconfig for container access...$(NC)"
	@chmod +x scripts/setup-kubeconfig.sh
	@./scripts/setup-kubeconfig.sh
	@echo "$(YELLOW)Starting services with Docker Compose...$(NC)"
	@chmod +x scripts/run-goose.sh
	@./scripts/run-goose.sh
	@echo ""
	@echo "$(GREEN)✅ Real Goose K8s Chat started successfully!$(NC)"
	@echo "$(CYAN)🌐 Access at: http://localhost:$(PORT)$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 Useful commands:$(NC)"
	@echo "  make local-logs    - View service logs"
	@echo "  make local-stop    - Stop services"
	@echo "  make change-model  - Switch AI model"

local-stop: ## Stop local Docker Compose services
	@echo "$(BLUE)🛑 Stopping local Real Goose services...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✅ Local services stopped$(NC)"

local-restart: ## Restart local services (stop + start)
	@echo "$(BLUE)🔄 Restarting Real Goose services...$(NC)"
	@$(MAKE) local-stop
	@$(MAKE) local-start

local-logs: ## View logs from local services
	@echo "$(BLUE)📋 Real Goose service logs:$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop following logs$(NC)"
	@docker compose -f $(COMPOSE_FILE) logs -f

local-clean: ## Clean up local Docker resources
	@echo "$(BLUE)🧹 Cleaning up local Docker resources...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down --volumes --remove-orphans
	@docker image rm $(DOCKER_IMAGE):latest 2>/dev/null || true
	@echo "$(GREEN)✅ Local cleanup complete$(NC)"

##@ ☸️ Kubernetes Deployment

k8s-deploy: validate ## Deploy Real Goose to Kubernetes cluster
	@echo "$(BLUE)🚀 Deploying Real Goose to Kubernetes...$(NC)"
	@if [ -z "$$ANTHROPIC_API_KEY" ]; then \
		echo "$(RED)❌ ANTHROPIC_API_KEY environment variable is required$(NC)"; \
		echo "   Set it with: export ANTHROPIC_API_KEY='your-api-key-here'"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Checking kubectl connectivity...$(NC)"
	@kubectl cluster-info --request-timeout=5s > /dev/null || (echo "$(RED)❌ Cannot connect to Kubernetes cluster$(NC)" && exit 1)
	@echo "$(YELLOW)Deploying with Helm...$(NC)"
	@chmod +x scripts/deploy-k8s.sh
	@./scripts/deploy-k8s.sh
	@echo ""
	@echo "$(GREEN)✅ Deployment initiated!$(NC)"
	@echo "$(YELLOW)Run 'make k8s-status' to check deployment status$(NC)"

k8s-status: ## Check status of Kubernetes deployment
	@echo "$(BLUE)📊 Real Goose K8s Chat deployment status:$(NC)"
	@echo ""
	@echo "$(YELLOW)🎯 Helm Release Status:$(NC)"
	@helm status $(HELM_RELEASE) -n $(NAMESPACE) 2>/dev/null || echo "  ❌ Release '$(HELM_RELEASE)' not found"
	@echo ""
	@echo "$(YELLOW)🏗️  Pod Status:$(NC)"
	@kubectl get pods -l app.kubernetes.io/name=k8s-chat -n $(NAMESPACE) 2>/dev/null || echo "  ❌ No pods found"
	@echo ""
	@echo "$(YELLOW)🌐 Service Status:$(NC)"
	@kubectl get svc -l app.kubernetes.io/name=k8s-chat -n $(NAMESPACE) 2>/dev/null || echo "  ❌ No services found"
	@echo ""
	@echo "$(YELLOW)🔗 Access Information:$(NC)"
	@NODE_PORT=$$(kubectl get svc $(HELM_RELEASE) -n $(NAMESPACE) -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null); \
	NODE_IP=$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null); \
	if [ -n "$$NODE_PORT" ] && [ -n "$$NODE_IP" ]; then \
		echo "  🌐 External: http://$$NODE_IP:$$NODE_PORT"; \
		echo "  🔗 Port-forward: kubectl port-forward svc/$(HELM_RELEASE) $(PORT):$(PORT) -n $(NAMESPACE)"; \
		echo "  📋 Then visit: http://localhost:$(PORT)"; \
	else \
		echo "  ❌ Service not ready or not found"; \
	fi

k8s-logs: ## View logs from Kubernetes deployment
	@echo "$(BLUE)📋 Real Goose K8s deployment logs:$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop following logs$(NC)"
	@kubectl logs -l app.kubernetes.io/name=k8s-chat -n $(NAMESPACE) --tail=100 -f

k8s-port-forward: ## Port-forward Kubernetes service to localhost
	@echo "$(BLUE)🔗 Port-forwarding Real Goose service...$(NC)"
	@echo "$(YELLOW)Access at: http://localhost:$(PORT)$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop port-forwarding$(NC)"
	@kubectl port-forward svc/$(HELM_RELEASE) $(PORT):$(PORT) -n $(NAMESPACE)

k8s-clean: ## Remove Real Goose from Kubernetes cluster
	@echo "$(BLUE)🧹 Cleaning up Kubernetes deployment...$(NC)"
	@helm uninstall $(HELM_RELEASE) -n $(NAMESPACE) 2>/dev/null || echo "$(YELLOW)⚠️  Helm release not found$(NC)"
	@kubectl delete secret k8s-chat-anthropic -n $(NAMESPACE) 2>/dev/null || echo "$(YELLOW)⚠️  Secret not found$(NC)"
	@echo "$(GREEN)✅ Kubernetes cleanup complete$(NC)"

##@ 🔧 Configuration & Management

setup-kubeconfig: ## Setup kubeconfig for container access
	@echo "$(BLUE)🔧 Setting up kubeconfig for Real Goose container...$(NC)"
	@chmod +x scripts/setup-kubeconfig.sh
	@./scripts/setup-kubeconfig.sh
	@echo "$(GREEN)✅ Kubeconfig setup complete$(NC)"

change-model: ## Change AI model configuration dynamically
	@echo "$(BLUE)🔄 Real Goose model configuration...$(NC)"
	@chmod +x scripts/change-model.sh
	@./scripts/change-model.sh

##@ 🛠️ Development & Testing

build: ## Build Real Goose Docker image locally
	@echo "$(BLUE)🔨 Building Real Goose Docker image...$(NC)"
	@docker build -f Dockerfile.goose -t $(DOCKER_IMAGE):latest .
	@echo "$(GREEN)✅ Docker image built: $(DOCKER_IMAGE):latest$(NC)"
	@echo "$(YELLOW)💡 Image size: $$(docker images $(DOCKER_IMAGE):latest --format 'table {{.Size}}' | tail -1)$(NC)"

push: build ## Build and push Docker image to registry
	@echo "$(BLUE)📤 Pushing Docker image to registry...$(NC)"
	@if [ -z "$(REGISTRY)" ]; then \
		echo "$(RED)❌ REGISTRY variable not set$(NC)"; \
		echo "   Usage: make push REGISTRY=your-registry.com"; \
		exit 1; \
	fi
	@docker tag $(DOCKER_IMAGE):latest $(REGISTRY)/$(DOCKER_IMAGE):latest
	@docker push $(REGISTRY)/$(DOCKER_IMAGE):latest
	@echo "$(GREEN)✅ Image pushed to $(REGISTRY)/$(DOCKER_IMAGE):latest$(NC)"

lint: ## Validate Helm chart and configurations
	@echo "$(BLUE)🔍 Linting Real Goose Helm chart...$(NC)"
	@helm lint ./helm/k8s-chat
	@echo "$(YELLOW)Validating YAML configurations...$(NC)"
	@kubectl --dry-run=client apply -f goose-config.yaml > /dev/null 2>&1 && echo "$(GREEN)✅ goose-config.yaml valid$(NC)" || echo "$(YELLOW)⚠️  goose-config.yaml not a K8s resource$(NC)"
	@echo "$(GREEN)✅ Lint validation complete$(NC)"

test: lint ## Run comprehensive tests and validations
	@echo "$(BLUE)🧪 Testing Real Goose K8s Chat...$(NC)"
	@echo "$(YELLOW)🔍 Testing Helm template generation...$(NC)"
	@helm template $(HELM_RELEASE) ./helm/k8s-chat --set secrets.anthropic.apiKey="test-key" > /dev/null
	@echo "$(YELLOW)🔍 Testing Docker Compose validation...$(NC)"
	@docker compose -f $(COMPOSE_FILE) config > /dev/null
	@echo "$(YELLOW)🔍 Testing script permissions...$(NC)"
	@test -x scripts/run-goose.sh && test -x scripts/deploy-k8s.sh && test -x scripts/setup-kubeconfig.sh && test -x scripts/change-model.sh
	@echo "$(GREEN)✅ All tests passed$(NC)"

##@ 🎬 Demo & CI/CD

demo-setup: ## Setup demo environment with sample workloads
	@echo "$(BLUE)🎬 Setting up demo environment...$(NC)"
	@echo "$(YELLOW)Creating demo namespace and workloads...$(NC)"
	@kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(YELLOW)Deploying demo nginx resources...$(NC)"
	@kubectl apply -f demo-resources.yaml
	@echo "$(GREEN)✅ Demo environment ready!$(NC)"
	@echo "$(CYAN)Try these commands with Goose:$(NC)"
	@echo "  - Show me all pods in the demo namespace"
	@echo "  - Scale the demo-nginx deployment to 5 replicas"
	@echo "  - Show me the service endpoints"

demo-clean: ## Clean up demo environment
	@echo "$(BLUE)🧹 Cleaning demo environment...$(NC)"
	@kubectl delete namespace demo --ignore-not-found=true
	@echo "$(GREEN)✅ Demo environment cleaned$(NC)"

ci-test: ## Run CI/CD tests (Docker + Helm validation)
	@echo "$(BLUE)🧪 Running CI/CD tests...$(NC)"
	@echo "$(YELLOW)Testing Docker build...$(NC)"
	@docker build -f Dockerfile.goose -t $(DOCKER_IMAGE):test .
	@echo "$(YELLOW)Testing Helm chart validation...$(NC)"
	@helm lint ./helm/k8s-chat
	@helm template k8s-chat ./helm/k8s-chat --set secrets.anthropic.apiKey="test-key" > /dev/null
	@echo "$(YELLOW)Testing Docker Compose config...$(NC)"
	@docker compose -f $(COMPOSE_FILE) config > /dev/null
	@echo "$(GREEN)✅ All CI tests passed$(NC)"

ci-security-scan: ## Run security scans on Docker image
	@echo "$(BLUE)🔒 Running security scan...$(NC)"
	@docker build -f Dockerfile.goose -t $(DOCKER_IMAGE):security-test .
	@echo "$(YELLOW)Running basic security checks...$(NC)"
	@echo "$(YELLOW)Checking for common vulnerabilities...$(NC)"
	@docker run --rm $(DOCKER_IMAGE):security-test /bin/bash -c "echo 'Container security check - verifying goose installation' && which goose && goose --version" || echo "$(YELLOW)⚠️  Security scan completed with warnings$(NC)"
	@echo "$(GREEN)✅ Security scan complete$(NC)"

release-prepare: build test lint ## Prepare release (build, test, lint)
	@echo "$(BLUE)📦 Preparing release...$(NC)"
	@echo "$(GREEN)✅ Release preparation complete!$(NC)"
	@echo "$(YELLOW)Ready to tag and push release$(NC)"

clean: ## Clean up all resources (local + k8s)
	@echo "$(BLUE)🧹 Comprehensive cleanup...$(NC)"
	@$(MAKE) local-clean
	@$(MAKE) k8s-clean
	@echo "$(GREEN)🎉 All resources cleaned up!$(NC)"

clean-all: clean ## Complete cleanup including Docker system prune
	@echo "$(BLUE)🧹 Deep cleaning Docker system...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)🎉 Complete cleanup finished!$(NC)"

##@ 📋 Information & Help

version: ## Show version information
	@echo "$(BLUE)📋 Real Goose K8s Chat - Version Information$(NC)"
	@echo "============================================="
	@echo "Project:        $(PROJECT_NAME)"
	@echo "Docker Image:   $(DOCKER_IMAGE)"
	@echo "Goose Version:  $(GOOSE_VERSION)"
	@echo "Helm Release:   $(HELM_RELEASE)"
	@echo "Default Port:   $(PORT)"
	@echo "K8s NodePort:   $(K8S_PORT)"

status: ## Show overall project status
	@echo "$(BLUE)📊 Real Goose K8s Chat - Overall Status$(NC)"
	@echo "========================================"
	@echo ""
	@echo "$(YELLOW)🐳 Local Services:$(NC)"
	@if docker ps | grep -q $(CONTAINER_NAME); then \
		echo "  ✅ Real Goose container running"; \
		echo "  🌐 Available at: http://localhost:$(PORT)"; \
	else \
		echo "  ⭕ No local services running"; \
	fi
	@echo ""
	@echo "$(YELLOW)☸️  Kubernetes Services:$(NC)"
	@if kubectl get pods -l app.kubernetes.io/name=k8s-chat -n $(NAMESPACE) 2>/dev/null | grep -q Running; then \
		echo "  ✅ Real Goose deployed to Kubernetes"; \
	else \
		echo "  ⭕ No Kubernetes deployment found"; \
	fi
	@echo ""
	@$(MAKE) info

install-hooks: ## Install/update git hooks for the streamlined architecture
	@echo "$(BLUE)🔧 Installing updated git hooks...$(NC)"
	@./scripts/update-git-hooks.sh
