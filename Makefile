SHELL := /bin/bash
PROJECT := k8s-chat
VERSION ?= $(shell git rev-parse --short HEAD)
DOCKERHUB_USERNAME ?= your-dockerhub-username
IMAGE_NAME := $(DOCKERHUB_USERNAME)/$(PROJECT)

# Docker image names
IMAGE := $(IMAGE_NAME):$(VERSION)
IMAGE_LATEST := $(IMAGE_NAME):latest

# Docker Compose files
COMPOSE_FILE := docker-compose.yml
COMPOSE_DEV_FILE := docker-compose.dev.yml

.PHONY: help
help:
	@echo "K8s Chat - Available commands:"
	@echo ""
	@echo "📦 Building:"
	@echo "  make build           Build single container with all components"
	@echo "  make push            Push container to Docker Hub"
	@echo ""
	@echo "🚀 Running (Single Container):"
	@echo "  make run             Run full application (frontend + backend)"
	@echo "  make run-frontend-only Run frontend-only mode"
	@echo "  make run-backend-only Run backend-only mode"
	@echo "  make stop            Stop and remove containers"
	@echo "  make logs            Show container logs"
	@echo ""
	@echo "🛠️  Development (Native):"
	@echo "  make dev-backend     Run backend in development mode"
	@echo "  make dev-frontend    Run frontend in development mode"
	@echo "  make dev             Run both backend and frontend in development"
	@echo ""
	@echo "🐳 Docker Compose:"
	@echo "  make compose-up      Start all services with docker-compose"
	@echo "  make compose-down    Stop all services"
	@echo "  make compose-dev-up  Start development environment"
	@echo "  make compose-dev-down Stop development environment"
	@echo "  make compose-logs    Show logs from all services"
	@echo "  make compose-restart Restart all services"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  make test            Run tests"
	@echo "  make lint            Run linting"
	@echo "  make format          Format code"
	@echo ""
	@echo "☸️  Kubernetes:"
	@echo "  make helm-install    Install via Helm (single container mode)"
	@echo "  make helm-install-separate Install via Helm (separate containers)"
	@echo "  make helm-upgrade    Upgrade via Helm"
	@echo "  make helm-uninstall  Uninstall Helm release"
	@echo "  make k8s-status      Show status of k8s-chat namespace"
	@echo "  make k8s-logs        Show logs from k8s-chat namespace"
	@echo "  make k8s-describe    Describe all resources in k8s-chat namespace"
	@echo "  make k8s-delete-namespace Delete k8s-chat namespace (destructive!)"
	@echo ""
	@echo "  🔑 Note: Set ANTHROPIC_API_KEY environment variable before Helm operations"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean           Clean up local images and containers"
	@echo "  make install-deps    Install development dependencies"

.PHONY: build
build:
	@echo "Building single container with all components..."
	docker build -t $(IMAGE) -t $(IMAGE_LATEST) .

.PHONY: push
push: build
	@echo "Pushing single container to Docker Hub..."
	docker push $(IMAGE)
	docker push $(IMAGE_LATEST)

.PHONY: run
run:
	@echo "🚀 Running K8s Chat container..."
	@echo "Access at http://localhost:80"
	docker run -d \
		--name k8s-chat \
		-p 80:80 \
		-e ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
		-e ENABLE_BACKEND=true \
		-e ENABLE_FRONTEND=true \
		$(IMAGE_LATEST)

.PHONY: run-frontend-only
run-frontend-only:
	@echo "🎨 Running frontend-only mode..."
	@echo "Access at http://localhost:80"
	docker run -d \
		--name k8s-chat-frontend \
		-p 80:80 \
		-e ENABLE_BACKEND=false \
		-e ENABLE_FRONTEND=true \
		$(IMAGE_LATEST)

.PHONY: run-backend-only
run-backend-only:
	@echo "⚙️  Running backend-only mode..."
	@echo "API available at http://localhost:8000"
	docker run -d \
		--name k8s-chat-backend \
		-p 8000:8000 \
		-e ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
		-e ENABLE_BACKEND=true \
		-e ENABLE_FRONTEND=false \
		-e ENABLE_NGINX=false \
		$(IMAGE_LATEST)

.PHONY: stop
stop:
	@echo "🛑 Stopping K8s Chat containers..."
	docker stop k8s-chat k8s-chat-frontend k8s-chat-backend 2>/dev/null || true
	docker rm k8s-chat k8s-chat-frontend k8s-chat-backend 2>/dev/null || true

.PHONY: logs
logs:
	@echo "📋 Showing container logs..."
	docker logs -f k8s-chat 2>/dev/null || \
	docker logs -f k8s-chat-frontend 2>/dev/null || \
	docker logs -f k8s-chat-backend 2>/dev/null || \
	echo "No running containers found"

.PHONY: dev-backend
dev-backend:
	@echo "Starting backend in development mode..."
	cd backend && pip install -r requirements.txt
	cd backend && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

.PHONY: dev-frontend
dev-frontend:
	@echo "Starting frontend in development mode..."
	cd frontend && npm install
	cd frontend && npm run dev

.PHONY: dev
dev:
	@echo "Starting both services in development mode..."
	@echo "Backend will be available at http://localhost:8000"
	@echo "Frontend will be available at http://localhost:3000"
	@make -j2 dev-backend dev-frontend

.PHONY: test
test: test-backend test-frontend

.PHONY: test-backend
test-backend:
	@echo "Running backend tests..."
	cd backend && python -m pytest

.PHONY: test-frontend
test-frontend:
	@echo "Running frontend tests..."
	cd frontend && npm test

.PHONY: lint
lint: lint-backend lint-frontend

.PHONY: lint-backend
lint-backend:
	@echo "Linting backend code..."
	cd backend && python -m black --check .
	cd backend && python -m isort --check-only .
	cd backend && python -m mypy .

.PHONY: lint-frontend
lint-frontend:
	@echo "Linting frontend code..."
	cd frontend && npm run lint

.PHONY: format
format: format-backend format-frontend

.PHONY: format-backend
format-backend:
	@echo "Formatting backend code..."
	cd backend && python -m black .
	cd backend && python -m isort .

.PHONY: format-frontend
format-frontend:
	@echo "Formatting frontend code..."
	cd frontend && npm run lint -- --fix

.PHONY: clean
clean:
	@echo "Cleaning up Docker images and containers..."
	docker system prune -f
	docker rmi -f $(IMAGE) $(IMAGE_LATEST) 2>/dev/null || true

.PHONY: helm-install
helm-install:
	@echo "Installing K8s Chat via Helm..."
	@if [ -z "$(ANTHROPIC_API_KEY)" ]; then \
		echo "⚠️  Warning: ANTHROPIC_API_KEY environment variable is not set"; \
		echo "   Set it with: export ANTHROPIC_API_KEY=your_key_here"; \
	fi
	helm install $(PROJECT) ./helm/$(PROJECT) \
		--create-namespace \
		--namespace $(PROJECT) \
		--set image.app.repository=$(IMAGE_NAME) \
		--set image.app.tag=$(VERSION) \
		--set config.backend.anthropicApiKey="$(ANTHROPIC_API_KEY)"

.PHONY: helm-install-separate
helm-install-separate:
	@echo "Installing K8s Chat in separate container mode..."
	@if [ -z "$(ANTHROPIC_API_KEY)" ]; then \
		echo "⚠️  Warning: ANTHROPIC_API_KEY environment variable is not set"; \
		echo "   Set it with: export ANTHROPIC_API_KEY=your_key_here"; \
	fi
	helm install $(PROJECT) ./helm/$(PROJECT) \
		--create-namespace \
		--namespace $(PROJECT) \
		--set deploymentMode=separate \
		--set image.backend.repository=$(IMAGE_NAME)-backend \
		--set image.backend.tag=$(VERSION) \
		--set image.frontend.repository=$(IMAGE_NAME)-frontend \
		--set image.frontend.tag=$(VERSION) \
		--set config.backend.anthropicApiKey="$(ANTHROPIC_API_KEY)"

.PHONY: helm-upgrade
helm-upgrade:
	@echo "Upgrading K8s Chat via Helm..."
	@if [ -z "$(ANTHROPIC_API_KEY)" ]; then \
		echo "⚠️  Warning: ANTHROPIC_API_KEY environment variable is not set"; \
		echo "   Set it with: export ANTHROPIC_API_KEY=your_key_here"; \
	fi
	helm upgrade $(PROJECT) ./helm/$(PROJECT) \
		--namespace $(PROJECT) \
		--set image.app.repository=$(IMAGE_NAME) \
		--set image.app.tag=$(VERSION) \
		--set config.backend.anthropicApiKey="$(ANTHROPIC_API_KEY)"

.PHONY: helm-uninstall
helm-uninstall:
	@echo "Uninstalling K8s Chat..."
	helm uninstall $(PROJECT) --namespace $(PROJECT)

# Kubernetes namespace management
.PHONY: k8s-status
k8s-status:
	@echo "📊 Checking K8s Chat status..."
	@echo "Namespace: $(PROJECT)"
	@kubectl get namespace $(PROJECT) 2>/dev/null || echo "Namespace $(PROJECT) does not exist"
	@kubectl get all -n $(PROJECT) 2>/dev/null || echo "No resources in namespace $(PROJECT)"

.PHONY: k8s-logs
k8s-logs:
	@echo "📋 Showing logs from K8s Chat namespace..."
	@kubectl logs -n $(PROJECT) -l app.kubernetes.io/name=k8s-chat --tail=100 -f

.PHONY: k8s-describe
k8s-describe:
	@echo "🔍 Describing K8s Chat resources..."
	@kubectl describe all -n $(PROJECT)

.PHONY: k8s-delete-namespace
k8s-delete-namespace:
	@echo "⚠️  Deleting namespace $(PROJECT) and all resources..."
	@read -p "Are you sure? This will delete ALL resources in the $(PROJECT) namespace [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		kubectl delete namespace $(PROJECT); \
	else \
		echo "Cancelled."; \
	fi

# Docker Compose targets
.PHONY: compose-up
compose-up:
	@echo "🐳 Starting all services with docker-compose..."
	@echo "Backend: http://localhost:8000"
	@echo "Frontend: http://localhost:3000"
	@echo "MCP Server: http://localhost:8080"
	docker-compose -f $(COMPOSE_FILE) up -d --build

.PHONY: compose-down
compose-down:
	@echo "🛑 Stopping all services..."
	docker-compose -f $(COMPOSE_FILE) down -v

.PHONY: compose-dev-up
compose-dev-up:
	@echo "🔧 Starting development environment..."
	@echo "Backend (dev): http://localhost:8000"
	@echo "Frontend (dev): http://localhost:3000"
	docker-compose -f $(COMPOSE_DEV_FILE) up -d --build

.PHONY: compose-dev-down
compose-dev-down:
	@echo "🛑 Stopping development environment..."
	docker-compose -f $(COMPOSE_DEV_FILE) down -v

.PHONY: compose-logs
compose-logs:
	@echo "📋 Showing logs from all services..."
	docker-compose -f $(COMPOSE_FILE) logs -f

.PHONY: compose-restart
compose-restart:
	@echo "🔄 Restarting all services..."
	docker-compose -f $(COMPOSE_FILE) restart

.PHONY: compose-build
compose-build:
	@echo "🔨 Building all services..."
	docker-compose -f $(COMPOSE_FILE) build

# Legacy aliases for backward compatibility
.PHONY: docker-compose-up docker-compose-down
docker-compose-up: compose-up
docker-compose-down: compose-down

.PHONY: install-deps
install-deps:
	@echo "Installing development dependencies..."
	cd backend && pip install -r requirements.txt
	cd frontend && npm install
