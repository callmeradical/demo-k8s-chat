#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🦢 K8s Chat - Quick Start${NC}"
echo "================================"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is required but not installed${NC}"
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is required but not installed${NC}"
    exit 1
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
    cp docker-env.example .env
    echo -e "${RED}📝 Please edit .env file and add your ANTHROPIC_API_KEY${NC}"
    echo -e "${RED}   Then run this script again.${NC}"
    exit 1
fi

# Check if ANTHROPIC_API_KEY is set
if ! grep -q "ANTHROPIC_API_KEY=sk-" .env; then
    echo -e "${RED}❌ ANTHROPIC_API_KEY not configured in .env file${NC}"
    echo -e "${RED}   Please edit .env and add your API key from https://console.anthropic.com/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Choose mode
echo ""
echo -e "${YELLOW}🚀 Choose deployment mode:${NC}"
echo "1) Development mode (with hot reload)"
echo "2) Production mode"
echo "3) Show logs only"
echo "4) Stop all services"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo -e "${BLUE}🔧 Starting development environment...${NC}"
        make compose-dev-up
        echo ""
        echo -e "${GREEN}✅ Development environment started!${NC}"
        echo -e "${GREEN}🌐 Frontend: http://localhost:3000${NC}"
        echo -e "${GREEN}🔗 Backend: http://localhost:8000${NC}"
        echo ""
        echo "Press Ctrl+C to view logs, or run 'make compose-logs'"
        ;;
    2)
        echo -e "${BLUE}🚀 Starting production environment...${NC}"
        make compose-up
        echo ""
        echo -e "${GREEN}✅ Production environment started!${NC}"
        echo -e "${GREEN}🌐 Frontend: http://localhost:3000${NC}"
        echo -e "${GREEN}🔗 Backend: http://localhost:8000${NC}"
        echo ""
        echo "Press Ctrl+C to view logs, or run 'make compose-logs'"
        ;;
    3)
        echo -e "${BLUE}📋 Showing logs...${NC}"
        make compose-logs
        ;;
    4)
        echo -e "${BLUE}🛑 Stopping all services...${NC}"
        make compose-down
        make compose-dev-down
        echo -e "${GREEN}✅ All services stopped${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac
