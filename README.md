# K8s Chat - Goose-Powered Kubernetes Agent

A ChatGPT-like web interface for Kubernetes operations powered by Goose (the open-source AI agent framework) with Claude AI and custom K8s extensions.

## 🎯 Overview

K8s Chat leverages the powerful Goose agent framework to provide an intelligent conversational interface for Kubernetes cluster management. By building on Goose's extensible architecture, we get robust agent capabilities, session management, and tool integration out of the box.

This project creates a specialized K8s extension for Goose and provides a modern web interface for interacting with your clusters through natural language.

### 🌟 Key Capabilities

- **Goose-Powered AI Agent** - Leverages the robust Goose framework for agent capabilities
- **Natural Language K8s Operations** - Ask questions like "Show me failing pods" or "Scale the frontend deployment to 5 replicas"
- **Real-time Cluster Insights** - Live data from your cluster via MCP integration
- **Intelligent Troubleshooting** - AI-powered analysis with Goose's reasoning capabilities
- **Extensible Tool Framework** - Easy to add new K8s operations via Goose extensions
- **Session Management** - Persistent conversations with context awareness
- **Streaming Responses** - Real-time token-by-token response generation

## ✨ Features

- 🦢 **Goose Agent Framework** - Built on the proven open-source agent system
- 🤖 **AI-Powered Kubernetes Assistant** - Chat with Claude about your K8s cluster
- 🔄 **Real-time Streaming** - WebSocket-based streaming responses with typing indicators
- 🔧 **K8s Extension** - Custom Goose extension for Kubernetes operations
- 🔌 **MCP Integration** - Connect to Kubernetes MCP servers for live cluster data
- 📱 **Modern UI** - ChatGPT-like interface built with React and Material-UI
- 🐳 **Cloud Native** - Containerized and deployable via Helm
- 🔒 **Secure** - Non-root containers, security contexts, and secret management
- 📊 **Session Persistence** - Conversation history and context management

## 🏗️ Architecture

```
┌─────────────────┐    WebSocket    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │◄──────────────► │    Backend      │    │      Goose      │
│   (React)       │                 │   (FastAPI)     │◄──►│   Agent Core    │
│   - Chat UI     │                 │   - WebSocket   │    │   - Sessions    │
│   - Streaming   │                 │   - Proxy       │    │   - Providers   │
└─────────────────┘                 └─────────────────┘    └─────────────────┘
                                                                     │
                                             ┌───────────────────────┼───────────────────────┐
                                             │                       │                       │
                                    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
                                    │   Claude API    │    │  K8s Extension  │    │   K8s MCP       │
                                    │   - Streaming   │    │   - kubectl     │    │   Server        │
                                    │   - Sonnet 3.5  │    │   - Tools       │    │   - Live Data   │
                                    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Python 3.11+** and **Node.js 18+**
- **Docker** for containerization
- **Kubernetes cluster** (for deployment)
- **Anthropic API key** ([Get one here](https://console.anthropic.com/))
- **K8s MCP server** (optional - app works without it)

### 🛠️ Development Setup

1. **Clone and setup**
   ```bash
   git clone <repository-url>
   cd k8s-chat
   make install-deps
   ```

2. **Configure environment**
   ```bash
   cp backend/env.example backend/.env
   # Edit backend/.env and add your Anthropic API key
   ```

3. **Start services**
   ```bash
   # Start both services (recommended)
   make dev
   
   # Or start individually
   make dev-backend  # http://localhost:8000
   make dev-frontend # http://localhost:3000
   ```

4. **Access the application**
   - **Frontend**: http://localhost:3000
   - **Backend API**: http://localhost:8000
   - **Goose Sessions**: Available via API

### 💬 Example Conversations

```
User: What pods are running in the default namespace?
Goose: I'll check your cluster for you. Let me use the kubectl tool to get the current pods...
      [Uses k8s extension to execute: kubectl get pods -n default]
      
User: The frontend deployment seems slow, can you investigate?
Goose: I'll analyze the frontend deployment. Let me gather some information...
       [Uses multiple tools: get deployment, check pod status, analyze events]

User: Scale the api deployment to 3 replicas
Goose: I'll scale the api deployment to 3 replicas for you.
       [Executes: kubectl scale deployment api --replicas=3]
       ✅ Successfully scaled deployment "api" to 3 replicas
```

## ⚙️ Configuration

### Backend Environment Variables

```bash
# Required
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Goose Configuration
GOOSE_CONFIG_PATH=/path/to/goose/config
GOOSE_SESSION_TIMEOUT=3600

# Optional with sensible defaults
K8S_MCP_SERVER_URL=http://localhost:8080      # K8s MCP server
LOG_LEVEL=INFO                                # Logging level
DEBUG=false                                   # Debug mode
```

### Goose Configuration

Create a Goose configuration file for K8s Chat:

```yaml
# goose-config.yaml
providers:
  anthropic:
    api_key: ${ANTHROPIC_API_KEY}
    model: claude-3-5-sonnet-20241022
    max_tokens: 4096

extensions:
  - name: k8s-extension
    path: ./extensions/k8s
    config:
      mcp_server_url: ${K8S_MCP_SERVER_URL}
      default_namespace: default
      kubectl_context: current

session:
  timeout: 3600
  persistence: true
  storage: local
```

## 🔌 K8s Extension for Goose

The core of our system is a custom Goose extension that provides Kubernetes operations:

### Extension Structure
```
extensions/k8s/
├── __init__.py
├── tools/
│   ├── kubectl.py          # kubectl command execution
│   ├── cluster_info.py     # Cluster information
│   ├── pods.py             # Pod operations
│   ├── deployments.py      # Deployment management
│   └── helm.py             # Helm chart operations
├── resources/
│   ├── cluster_status.py   # Live cluster data
│   └── mcp_client.py       # MCP server integration
└── extension.py            # Main extension class
```

### Available Tools
- **kubectl**: Execute kubectl commands safely
- **get_pods**: List and filter pods
- **get_deployments**: List deployment information  
- **scale_deployment**: Scale deployments up/down
- **get_services**: List services and endpoints
- **get_nodes**: Node status and information
- **helm_list**: List Helm releases
- **helm_install**: Install Helm charts
- **cluster_health**: Overall cluster health check

## 🚀 Deployment

### Using Helm (Recommended for Production)

1. **Build and push images**
   ```bash
   # Set your Docker Hub username
   export DOCKERHUB_USERNAME=your-dockerhub-username
   export VERSION=$(git rev-parse --short HEAD)
   
   # Build and push to Docker Hub
   make build
   make push
   ```

2. **Deploy to Kubernetes**
   ```bash
   # The Helm chart will automatically create the k8s-chat namespace
   
   # Create secret for Anthropic API key (optional - chart can create it)
   kubectl create secret generic anthropic-secret \
     --from-literal=api-key=your-anthropic-api-key \
     -n k8s-chat
   
   # Install via Helm (automatically creates namespace)
   make helm-install
   
   # Check deployment status
   make k8s-status
   ```

### Using Docker Compose (Development)

For local development and testing, you can use Docker Compose to run all services:

```bash
# Quick start with docker-compose
cp docker-env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

# Production-like environment
make compose-up

# OR Development environment with hot reload
make compose-dev-up

# Access at:
# - Frontend: http://localhost:3000  
# - Backend API: http://localhost:8000
# - MCP Server: http://localhost:8080

# View logs
make compose-logs

# Stop everything
make compose-down
```

#### Docker Compose Commands

```bash
# Start all services (production images)
make compose-up

# Start development environment (with hot reload)
make compose-dev-up  

# Stop services
make compose-down
make compose-dev-down

# View logs from all services
make compose-logs

# Restart services
make compose-restart

# Build without starting
make compose-build
```

## 🏗️ Development

### Project Structure

```
k8s-chat/
├── backend/                    # FastAPI backend + Goose integration
│   ├── app/
│   │   ├── api/               # REST API routes
│   │   ├── config/            # Configuration
│   │   ├── services/          # Business logic
│   │   │   ├── goose_service.py      # Goose session management
│   │   │   └── websocket_service.py  # WebSocket streaming
│   │   └── main.py           # FastAPI app
│   ├── extensions/           # Goose extensions
│   │   └── k8s/             # K8s extension
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile           # Container definition
├── frontend/                 # React frontend
├── helm/                    # Helm chart
└── README.md               # This file
```

### Creating New K8s Tools

1. **Add a new tool file**:
   ```python
   # extensions/k8s/tools/my_tool.py
   from goose.toolkit.base import Tool
   
   class MyK8sTool(Tool):
       def __init__(self):
           super().__init__(
               name="my_k8s_tool",
               description="Description of what this tool does"
           )
       
       async def execute(self, **kwargs):
           # Implementation
           return result
   ```

2. **Register in extension**:
   ```python
   # extensions/k8s/extension.py
   from .tools.my_tool import MyK8sTool
   
   class K8sExtension(Extension):
       def get_tools(self):
           return [MyK8sTool(), ...]
   ```

## 🔒 Security & Production Considerations

### Security Features
- **API Keys**: Stored in Kubernetes secrets
- **Container Security**: Non-root users, security contexts
- **Goose Security**: Sandboxed tool execution
- **RBAC**: Kubernetes role-based access control
- **Network Policies**: Restrict pod-to-pod communication

### Production Checklist
- [ ] Configure Goose with production settings
- [ ] Set up proper RBAC for K8s extension
- [ ] Configure resource limits for agent operations
- [ ] Enable audit logging for kubectl operations
- [ ] Set up monitoring for Goose sessions
- [ ] Configure backup for session data

## 🤝 Contributing

### Development Guidelines
- Follow Goose extension development patterns
- Add tests for new K8s tools
- Update documentation for new capabilities
- Ensure security for kubectl operations

### Adding New Features
1. **New K8s Tools**: Extend the K8s extension with new tools
2. **UI Improvements**: Enhance the React frontend
3. **Goose Integration**: Improve session management and streaming
4. **MCP Integration**: Add new MCP server capabilities

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🗺️ Roadmap

### Current Features ✅
- Goose agent framework integration
- Custom K8s extension with basic tools
- Real-time chat interface with streaming
- Session management and persistence
- Kubernetes deployment via Helm

### Planned Features 🚧
- [ ] Advanced K8s operations (networking, storage)
- [ ] GitOps workflow integration
- [ ] Multi-cluster support via Goose contexts
- [ ] Advanced troubleshooting tools
- [ ] Performance monitoring integration
- [ ] Custom dashboard creation
- [ ] Voice input/output support
- [ ] Collaborative sessions

---

**Built with 🦢 Goose and ❤️ for the Kubernetes community**
