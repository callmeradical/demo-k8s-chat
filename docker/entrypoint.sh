#!/bin/bash
set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🦢 K8s Chat - Starting Services${NC}"
echo "=================================="

# Default values
ENABLE_BACKEND=${ENABLE_BACKEND:-true}
ENABLE_FRONTEND=${ENABLE_FRONTEND:-true}
ENABLE_NGINX=${ENABLE_NGINX:-true}

# Log configuration
echo -e "${YELLOW}📋 Configuration:${NC}"
echo "  ENABLE_BACKEND: ${ENABLE_BACKEND}"
echo "  ENABLE_FRONTEND: ${ENABLE_FRONTEND}"  
echo "  ENABLE_NGINX: ${ENABLE_NGINX}"
echo "  ANTHROPIC_API_KEY: $([ -n "$ANTHROPIC_API_KEY" ] && echo "✅ Set" || echo "❌ Not set")"
echo ""

# Validate required environment variables
if [ "$ENABLE_BACKEND" = "true" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${RED}❌ ANTHROPIC_API_KEY is required when ENABLE_BACKEND=true${NC}"
    exit 1
fi

# Create supervisord config based on enabled services
echo -e "${YELLOW}🔧 Configuring services...${NC}"

cat > /tmp/supervisord.conf << EOF
[unix_http_server]
file=/tmp/supervisor.sock

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/tmp/supervisord.pid
childlogdir=/var/log/supervisor
user=app
nodaemon=true

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

EOF

# Add backend service if enabled
if [ "$ENABLE_BACKEND" = "true" ]; then
    echo -e "${GREEN}✅ Enabling Backend Service${NC}"
    cat >> /tmp/supervisord.conf << EOF
[program:backend]
command=python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
directory=/app
user=app
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/backend.log
environment=PYTHONPATH="/app"

EOF
fi

# Add nginx service if enabled
if [ "$ENABLE_NGINX" = "true" ] && [ "$ENABLE_FRONTEND" = "true" ]; then
    echo -e "${GREEN}✅ Enabling Frontend (Nginx)${NC}"
    cat >> /tmp/supervisord.conf << EOF
[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
user=root
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/nginx.log

EOF
fi

# Copy the generated config
cp /tmp/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Update nginx config with backend proxy if backend is enabled
if [ "$ENABLE_BACKEND" = "true" ]; then
    sed -i 's/# proxy_pass http:\/\/localhost:8000;/proxy_pass http:\/\/localhost:8000;/' /etc/nginx/nginx.conf
fi

echo -e "${GREEN}🚀 Starting services with supervisord...${NC}"
echo ""

# Execute the command
exec "$@"
