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

# Create directories that app user can write to
mkdir -p /app/config /app/logs /var/log/supervisor
chmod -R 755 /app/config /app/logs /var/log/supervisor

# Create supervisord config in app directory instead of /etc
echo -e "${YELLOW}🔧 Configuring services...${NC}"

cat > /app/config/supervisord.conf << EOF
[unix_http_server]
file=/tmp/supervisor.sock
chmod=0700

[supervisord]
logfile=/app/logs/supervisord.log
pidfile=/tmp/supervisord.pid
childlogdir=/app/logs
nodaemon=true

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

EOF

# Add backend service if enabled
if [ "$ENABLE_BACKEND" = "true" ]; then
    echo -e "${GREEN}✅ Enabling Backend Service${NC}"
    cat >> /app/config/supervisord.conf << EOF
[program:backend]
command=python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
directory=/app
user=app
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/app/logs/backend.log
environment=PYTHONPATH="/app"

EOF
fi

# Add nginx service if enabled
if [ "$ENABLE_NGINX" = "true" ] && [ "$ENABLE_FRONTEND" = "true" ]; then
    echo -e "${GREEN}✅ Enabling Frontend (Nginx)${NC}"

    # Create nginx config in app directory
    cp /etc/nginx/nginx.conf /app/config/nginx.conf

    # Update nginx config with backend proxy if backend is enabled
    if [ "$ENABLE_BACKEND" = "true" ]; then
        sed -i 's/# proxy_pass http:\/\/localhost:8000;/proxy_pass http:\/\/localhost:8000;/' /app/config/nginx.conf
    fi

    cat >> /app/config/supervisord.conf << EOF
[program:nginx]
command=/usr/sbin/nginx -c /app/config/nginx.conf -g "daemon off;"
user=root
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/app/logs/nginx.log

EOF
fi

echo -e "${GREEN}🚀 Starting services with supervisord...${NC}"
echo ""

# Start supervisord with the config in app directory
exec supervisord -c /app/config/supervisord.conf
