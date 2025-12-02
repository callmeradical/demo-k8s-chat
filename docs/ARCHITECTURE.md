# K8s Chat - Architecture Overview

## nginx + systemd Services Container Architecture

This implementation uses nginx as a reverse proxy with systemd managing the lifecycle of all services within a single container, providing proper service management and restart capabilities.

### Architecture Components

```
┌─────────────────┐
│   User Browser  │
└─────────┬───────┘
          │ :8080
          ▼
┌─────────────────┐
│     nginx       │  ← Reverse Proxy (systemd managed)
│   (Port 8080)   │
└─────────┬───────┘
          │
          ├─ /              → Wrapper (:3000)
          ├─ /set-api-key   → Wrapper (:3000)
          ├─ /health        → Wrapper (:3000)
          │
          ├─ /goose/        → Goose (:3001)
          ├─ /static/       → Goose (:3001)
          ├─ /session/      → Goose (:3001)
          └─ /api/          → Goose (:3001)

┌─────────────────┐
│    systemd      │  ← Service Manager
├─────────────────┤
│ wrapper.service │  ← Always running
│ nginx.service   │  ← Always running
│ goose.service   │  ← Started on demand
└─────────────────┘
```

### systemd Service Management

#### Service Units:
- **`k8s-chat-wrapper.service`** - API key wrapper (always running)
- **`nginx.service`** - Reverse proxy (always running)
- **`goose.service`** - Goose application (started on demand)
- **`k8s-chat.target`** - Service group coordinator

#### Service Flow:

1. **Container Startup:**
   - systemd starts as PID 1 (`/sbin/init`)
   - `k8s-chat.target` brings up core services
   - wrapper service starts on port 3000
   - nginx service starts on port 8080
   - Goose service remains stopped (waiting for API key)

2. **API Key Submission:**
   - User submits API key to wrapper service
   - Wrapper uses `systemctl set-environment` to set API key
   - Wrapper uses `systemctl start goose.service` to launch Goose
   - nginx automatically routes `/goose/` requests to Goose

3. **Service Restart on API Key Change:**
   - Wrapper stops existing Goose service: `systemctl stop goose.service`
   - Sets new environment variables with new API key
   - Starts Goose with new key: `systemctl start goose.service`

### Benefits

- **Proper Service Management:** systemd handles service lifecycle, restart policies, and dependencies
- **Clean Separation:** Each service runs in its own systemd unit with proper isolation
- **Automatic Restart:** Services automatically restart on failure
- **Environment Management:** API keys managed through systemd environment
- **Robust Proxying:** nginx handles all the complex routing
- **Single Container:** All services run in one container but properly managed
- **Production Ready:** systemd is the standard for service management
- **Logging:** Centralized logging through journald

### Files

- `systemd/k8s-chat-wrapper.service` - Wrapper service definition
- `systemd/goose.service` - Goose service definition (on-demand)
- `systemd/nginx.service` - nginx proxy service
- `systemd/k8s-chat.target` - Service group
- `goose-wrapper-simple.js` - Wrapper with systemctl integration
- `nginx.conf` - nginx reverse proxy configuration
- `Dockerfile` - systemd-enabled container build

## Usage

### Local Development
```bash
# Build and run with docker-compose (requires privileged mode for systemd)
docker compose up --build

# Access at http://localhost:8080
```

### Check Service Status
```bash
# Get container shell
docker exec -it <container-name> bash

# Check all services
systemctl status k8s-chat.target

# Check individual services
systemctl status k8s-chat-wrapper
systemctl status nginx
systemctl status goose

# View logs
journalctl -u k8s-chat-wrapper -f
journalctl -u goose -f
```

### Production Deployment
```bash
# Build image
docker build -t k8s-chat .

# Run container (requires privileged mode)
docker run --privileged -p 8080:8080 \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  k8s-chat

# Or deploy to Kubernetes with proper security context
```

### Testing the Flow

1. **Visit** `http://localhost:8080`
2. **Enter** your Anthropic API key
3. **Click** "Launch K8s Chat" or "Skip Validation (Dev Mode)"
4. **Wrapper calls** `systemctl start goose.service` with your API key
5. **Access** the full Goose chat interface with proper styling and WebSocket connectivity

The systemd integration provides proper service lifecycle management while nginx handles all the routing complexity!
