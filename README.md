# K8s Chat - Real Goose Powered Kubernetes Assistant

A containerized web interface for the real Goose AI agent framework, specifically configured for Kubernetes cluster management. This application packages the official Goose Rust binary in a Docker container with all necessary tools for intelligent Kubernetes operations.

## 🎯 Getting Started

**TL;DR - Quick Start:**
```bash
# 1. Check prerequisites
make info

# 2. Set API key
export ANTHROPIC_API_KEY="your-key-here"

# 3. Start locally
make local-start

# 4. Or deploy to Kubernetes
make k8s-deploy
```

Visit `http://localhost:3000` and start chatting with your K8s assistant! 🦢

## 🆕 Now with Real Goose!

This application now uses the **actual Goose framework** (written in Rust) instead of a Python simulation, providing:

- **Authentic Goose Experience**: Real tool integration and session management
- **Built-in Extensions**: Developer tools, computer controller, extension manager, and more
- **Proper Tool Execution**: Actual kubectl command execution via Goose's developer extension
- **Rich Ecosystem**: Access to Goose's full extension marketplace
- **Session Persistence**: Native Goose session storage and chat recall

## 🎯 Overview

K8s Chat leverages the powerful Goose agent framework to provide an intelligent conversational interface for Kubernetes cluster management. By using the official Goose binary, we get robust agent capabilities, session management, and tool integration out of the box.

### 🌟 Key Capabilities

- **Real Goose Framework** - Uses the actual Rust-based Goose binary (v1.14.2)
- **Natural Language K8s Operations** - Ask questions like "Show me failing pods" or "Scale the frontend deployment to 5 replicas"
- **Real-time Cluster Insights** - Live kubectl execution via developer extension
- **Intelligent Troubleshooting** - AI-powered analysis with Goose's reasoning capabilities
- **Extensible Tool Framework** - Access to Goose's full extension ecosystem
- **Session Management** - Persistent conversations with context awareness
- **Streaming Responses** - Real-time token-by-token response generation

## ✨ Features

- 🦢 **Real Goose Agent Framework** - Official Rust binary running in container
- 🤖 **AI-Powered Kubernetes Assistant** - Chat with Claude/GPT/Gemini about your K8s cluster
- 🔄 **Real-time Streaming** - Goose's built-in web interface with streaming responses
- 🔧 **Developer Extension** - Native kubectl execution and shell access
- 🔌 **Extension Ecosystem** - Computer controller, extension manager, chat recall, todo
- 🐳 **Containerized** - Secure, reproducible environment with kubectl pre-installed
- 🔒 **Secure** - Non-root containers, mounted kubeconfig, volume persistence
- 📊 **Session Persistence** - Conversation history and context management

## 🏗️ Architecture

```
┌─────────────────┐    HTTP/WebSocket   ┌─────────────────┐
│   Web Browser   │◄──────────────────► │  Goose Web UI   │
│   - User Input  │                     │  (Rust Binary)  │
│   - Chat UI     │                     │  - Sessions     │
│   - Streaming   │                     │  - Extensions   │
└─────────────────┘                     └─────────────────┘
                                                  │
                           ┌──────────────────────┼──────────────────────┐
                           │                      │                      │
                  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
                  │  Claude/GPT/    │   │   Developer     │   │     kubectl     │
                  │  Gemini API     │   │   Extension     │   │   (in container)│
                  │  - Streaming    │   │   - Shell       │   │   - K8s API     │
                  └─────────────────┘   └─────────────────┘   └─────────────────┘
```

## Prerequisites

- Docker and Docker Compose (for local testing)
- Kubernetes cluster (for production deployment)
- Helm 3+ (for Kubernetes deployment)
- Anthropic API key (recommended) or other supported provider keys

## 🚀 Quick Start

### Prerequisites Check
```bash
make info  # Check environment and show quick start guide
```

### Option 1: Local Testing with Docker Compose (Recommended for development)

1. **Clone and navigate**:
   ```bash
   git clone <repository-url>
   cd demo-k8s-chat
   ```

2. **Set your API key**:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-api03-your-api-key-here"
   ```

3. **Start Real Goose locally**:
   ```bash
   make local-start
   ```

4. **Access the interface**:
   Visit `http://localhost:3000`

### Option 2: Kubernetes Deployment (Production)

1. **Set your API key**:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-api03-your-api-key-here"
   ```

2. **Deploy to Kubernetes**:
   ```bash
   make k8s-deploy
   ```

3. **Check deployment status**:
   ```bash
   make k8s-status
   ```

### Available Make Commands

View all available commands:
```bash
make help
```

**Local Development:**
- `make local-start` - Start Real Goose with Docker Compose
- `make local-stop` - Stop local services
- `make local-logs` - View service logs
- `make local-clean` - Clean up local resources

**Kubernetes Operations:**
- `make k8s-deploy` - Deploy to Kubernetes cluster
- `make k8s-status` - Check deployment status
- `make k8s-logs` - View deployment logs
- `make k8s-clean` - Remove from cluster

**Configuration:**
- `make change-model` - Switch AI models dynamically
- `make setup-kubeconfig` - Setup container kubeconfig

**Development:**
- `make build` - Build Docker image
- `make lint` - Validate Helm chart
- `make test` - Run tests and validations
- `make clean` - Clean all resources

## 💬 Usage Examples

Once running, you can immediately start chatting with your Kubernetes assistant:

```
User: Show me all pods in the default namespace
Goose: I'll check your cluster for you. Let me use kubectl to get the current pods...
      [Executes: kubectl get pods -n default]

User: The frontend deployment seems slow, can you investigate?
Goose: I'll analyze the frontend deployment. Let me gather some information...
       [Uses multiple kubectl commands: get deployment, describe pods, check events]

User: Scale the api deployment to 3 replicas
Goose: I'll scale the api deployment to 3 replicas for you.
       [Executes: kubectl scale deployment api --replicas=3]
       ✅ Successfully scaled deployment "api" to 3 replicas
```

## ⚙️ Configuration

### Environment Variables

```bash
# Required
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Optional
GOOSE_MODEL=claude-3-5-sonnet-20241022  # Default model
GOOSE_PROVIDER=anthropic                # Default provider
```

### Goose Configuration

The container includes a pre-configured `goose-config.yaml` with:

```yaml
# Goose Configuration for K8s Chat Container
ANTHROPIC_HOST: https://api.anthropic.com
GOOSE_PROVIDER: anthropic
GOOSE_MODEL: claude-3-5-sonnet-20241022

# Extensions configuration
extensions:
  developer:
    enabled: true           # kubectl and shell access
  chatrecall:
    enabled: true          # Search conversation history
  todo:
    enabled: true          # Task management
  extensionmanager:
    enabled: true          # Discover new extensions
  computercontroller:
    enabled: true          # File operations and automation
```

## 🔌 Available Extensions

The containerized Goose includes these powerful extensions:

### Developer Extension
- **kubectl commands**: Direct Kubernetes cluster access
- **Shell access**: Full bash shell for complex operations
- **File operations**: Read/write files for configuration management

### Computer Controller
- **Web scraping**: Gather information from web sources
- **File caching**: Store and manage downloaded files
- **Automation scripts**: Create and run shell/Ruby scripts

### Extension Manager
- **Discover extensions**: Find new tools for your workflow
- **Enable/disable**: Manage which extensions are active
- **Extension marketplace**: Access to community extensions

### Chat Recall
- **Search history**: Find previous conversations and solutions
- **Session summaries**: Quick overview of past work
- **Context loading**: Restore previous conversation context

### Todo Management
- **Task tracking**: Keep track of complex multi-step operations
- **Progress updates**: Mark completed tasks and next steps
- **Workflow management**: Organize Kubernetes operations

## 🔒 Security Features

- **Non-root container**: Runs as unprivileged user
- **Read-only kubeconfig**: Your cluster credentials are mounted read-only
- **Volume isolation**: Sessions and logs stored in isolated volumes
- **API key security**: Environment variables for secure key storage
- **Container isolation**: Sandboxed execution environment

## 🚀 Deployment Options

### Local Development
```bash
./run-goose.sh
```

### Production Deployment
```bash
# Build production image
docker-compose -f docker-compose.goose.yml build

# Deploy with proper secrets management
docker-compose -f docker-compose.goose.yml up -d
```

### Kubernetes Deployment
```bash
# Create secret for API key
kubectl create secret generic anthropic-secret \
  --from-literal=api-key=your-anthropic-api-key

# Deploy using the provided manifests
kubectl apply -f k8s/
```

## 🛠️ Development

### Project Structure

```
demo-k8s-chat/
├── Makefile                     # Primary interface for all operations
├── Dockerfile.goose             # Real Goose container definition
├── docker-compose.goose.yml     # Docker Compose for local testing
├── goose-config.yaml           # Goose configuration file
├── scripts/                    # All operational scripts
│   ├── run-goose.sh           # Local development script
│   ├── deploy-k8s.sh          # Kubernetes deployment script
│   ├── setup-kubeconfig.sh    # Kubernetes authentication setup
│   └── change-model.sh        # Dynamic model configuration
├── helm/k8s-chat/             # Helm chart for Kubernetes deployment
│   ├── Chart.yaml            # Chart metadata
│   ├── values.yaml           # Configuration values
│   └── templates/            # Kubernetes manifests
├── README.md                  # This documentation
└── KUBERNETES_AUTH_SETUP.md   # Kubernetes authentication guide
```

### Customizing Extensions

You can modify `goose-config.yaml` to:
- Enable/disable specific extensions
- Configure extension parameters
- Add custom extension configurations

### Building Custom Images

```bash
# Build with custom Goose version
docker build -f Dockerfile.goose \
  --build-arg GOOSE_VERSION=1.14.2 \
  -t k8s-chat-goose:custom .

# Run with custom image
docker run -p 3000:3000 \
  -e ANTHROPIC_API_KEY=your-key \
  -v ~/.kube:/home/goose/.kube:ro \
  k8s-chat-goose:custom
```

## 🤝 Contributing

1. **Extension Development**: Create new Goose extensions for specific K8s operations
2. **Configuration**: Improve the default Goose configuration
3. **Documentation**: Add examples and use cases
4. **Container Optimization**: Improve the Docker image size and security

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🗺️ Roadmap

### Current Features ✅
- Real Goose framework integration (Rust binary)
- Containerized deployment with Docker
- Pre-configured extensions for K8s operations
- kubectl integration via developer extension
- Session persistence and chat recall

### Planned Features 🚧
- [ ] Kubernetes-specific extension development
- [ ] Helm chart for K8s deployment
- [ ] Multi-cluster support
- [ ] Advanced monitoring integrations
- [ ] Custom dashboard creation
- [ ] GitOps workflow integration

---

**Built with 🦢 Real Goose and ❤️ for the Kubernetes community**
