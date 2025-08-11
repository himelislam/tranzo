#!/bin/bash

# Tranzo - Service Shutdown Script
# This script stops all Tranzo services

set -e

echo "🛑 Stopping Tranzo Services..."
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Stop Node.js processes
stop_node_processes() {
    echo -e "\n${BLUE}🔧 Stopping Node.js processes...${NC}"
    
    # Find and kill backend processes
    BACKEND_PIDS=$(pgrep -f "node.*index.js" || true)
    if [ -n "$BACKEND_PIDS" ]; then
        echo "🛑 Stopping backend processes: $BACKEND_PIDS"
        kill $BACKEND_PIDS || true
        echo -e "${GREEN}✅ Backend processes stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  No backend processes found${NC}"
    fi
    
    # Find and kill frontend processes
    FRONTEND_PIDS=$(pgrep -f "next dev" || true)
    if [ -n "$FRONTEND_PIDS" ]; then
        echo "🛑 Stopping frontend processes: $FRONTEND_PIDS"
        kill $FRONTEND_PIDS || true
        echo -e "${GREEN}✅ Frontend processes stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  No frontend processes found${NC}"
    fi
    
    # Kill any remaining npm processes
    NPM_PIDS=$(pgrep -f "npm.*dev" || true)
    if [ -n "$NPM_PIDS" ]; then
        echo "🛑 Stopping npm processes: $NPM_PIDS"
        kill $NPM_PIDS || true
        echo -e "${GREEN}✅ NPM processes stopped${NC}"
    fi
}

# Stop Docker containers
stop_docker_containers() {
    echo -e "\n${BLUE}🐳 Stopping Docker containers...${NC}"
    
    # Stop Redis container
    if docker ps | grep -q "tranzo-redis"; then
        echo "🛑 Stopping Redis container..."
        docker stop tranzo-redis || true
        echo -e "${GREEN}✅ Redis container stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  Redis container not running${NC}"
    fi
    
    # Stop LibreTranslate container
    if docker ps | grep -q "tranzo-libretranslate"; then
        echo "🛑 Stopping LibreTranslate container..."
        docker stop tranzo-libretranslate || true
        echo -e "${GREEN}✅ LibreTranslate container stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  LibreTranslate container not running${NC}"
    fi
}

# Clean up function
cleanup() {
    echo -e "\n${BLUE}🧹 Cleaning up...${NC}"
    
    # Remove any temporary files
    if [ -f "test-upload.txt" ]; then
        rm test-upload.txt
        echo "🗑️  Removed test files"
    fi
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main execution
main() {
    stop_node_processes
    
    # Check if Docker is available before trying to stop containers
    if command -v docker &> /dev/null; then
        stop_docker_containers
    else
        echo -e "${YELLOW}⚠️  Docker not available - skipping container cleanup${NC}"
    fi
    
    cleanup
    
    echo -e "\n${GREEN}🎉 All Tranzo services stopped successfully!${NC}"
    echo "============================================="
    echo -e "${BLUE}💡 To start services again:${NC}"
    echo "   ./start-services.sh"
    echo ""
    echo -e "${YELLOW}📝 Note:${NC} Local Redis/LibreTranslate services may still be running"
    echo "   Check manually if needed:"
    echo "   - Redis: brew services stop redis"
    echo "   - LibreTranslate: kill the process manually"
}

# Run main function
main "$@"
