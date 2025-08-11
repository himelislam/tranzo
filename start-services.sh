#!/bin/bash

# Tranzo - Complete Service Startup Script
# This script starts all required services for the Tranzo application

set -e

echo "🚀 Starting Tranzo Services..."
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    local host=${3:-localhost}
    
    if curl -s "http://$host:$port" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name is running on port $port${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not running on port $port${NC}"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if check_service "$service_name" "$port" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}   Attempt $attempt/$max_attempts - waiting...${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service_name failed to start after $max_attempts attempts${NC}"
    return 1
}

# Check if Docker is available
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker is available${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Docker not found - will use local services${NC}"
        return 1
    fi
}

# Start Redis
start_redis() {
    echo -e "\n${BLUE}📦 Starting Redis...${NC}"
    
    if check_service "Redis" "6379" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Redis is already running${NC}"
        return 0
    fi
    
    if check_docker; then
        echo "🐳 Starting Redis with Docker..."
        docker run -d --name tranzo-redis -p 6379:6379 redis:alpine || {
            echo -e "${YELLOW}⚠️  Docker container might already exist, trying to start existing one...${NC}"
            docker start tranzo-redis || {
                echo -e "${RED}❌ Failed to start Redis with Docker${NC}"
                return 1
            }
        }
        wait_for_service "Redis" "6379"
    else
        echo -e "${YELLOW}⚠️  Please start Redis manually:${NC}"
        echo "   brew services start redis  # macOS"
        echo "   sudo systemctl start redis-server  # Linux"
        echo "   redis-server  # Windows"
        return 1
    fi
}

# Start LibreTranslate (optional)
start_libretranslate() {
    echo -e "\n${BLUE}🌐 Starting LibreTranslate...${NC}"
    
    if check_service "LibreTranslate" "5001" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ LibreTranslate is already running${NC}"
        return 0
    fi
    
    if check_docker; then
        echo "🐳 Starting LibreTranslate with Docker..."
        docker run -d --name tranzo-libretranslate -p 5001:5000 libretranslate/libretranslate || {
            echo -e "${YELLOW}⚠️  Docker container might already exist, trying to start existing one...${NC}"
            docker start tranzo-libretranslate || {
                echo -e "${YELLOW}⚠️  LibreTranslate failed to start - you can use Google Translate API instead${NC}"
                return 1
            }
        }
        wait_for_service "LibreTranslate" "5001"
    else
        echo -e "${YELLOW}⚠️  LibreTranslate not started. Options:${NC}"
        echo "   1. Install: pip install libretranslate"
        echo "   2. Run: libretranslate --host 0.0.0.0 --port 5001"
        echo "   3. Or configure Google Cloud Translate API"
        return 1
    fi
}

# Start backend
start_backend() {
    echo -e "\n${BLUE}⚙️  Starting Backend...${NC}"
    
    if check_service "Backend" "3001" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is already running${NC}"
        return 0
    fi
    
    echo "🔧 Starting Express.js backend..."
    npm run backend:dev &
    BACKEND_PID=$!
    
    wait_for_service "Backend" "3001"
}

# Start frontend
start_frontend() {
    echo -e "\n${BLUE}🌐 Starting Frontend...${NC}"
    
    if check_service "Frontend" "3002" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend is already running${NC}"
        return 0
    fi
    
    echo "⚛️  Starting Next.js frontend..."
    npm run dev &
    FRONTEND_PID=$!
    
    wait_for_service "Frontend" "3002"
}

# Main execution
main() {
    echo -e "${BLUE}🔍 Checking current service status...${NC}"
    
    # Check what's already running
    check_service "Redis" "6379" || echo "   Redis needs to be started"
    check_service "LibreTranslate" "5001" || echo "   LibreTranslate is optional"
    check_service "Backend" "3001" || echo "   Backend needs to be started"
    check_service "Frontend" "3002" || echo "   Frontend needs to be started"
    
    # Start services
    start_redis || {
        echo -e "${RED}❌ Redis is required but failed to start${NC}"
        exit 1
    }
    
    start_libretranslate || {
        echo -e "${YELLOW}⚠️  LibreTranslate not available - make sure to configure Google Translate API${NC}"
    }
    
    start_backend || {
        echo -e "${RED}❌ Backend failed to start${NC}"
        exit 1
    }
    
    start_frontend || {
        echo -e "${RED}❌ Frontend failed to start${NC}"
        exit 1
    }
    
    echo -e "\n${GREEN}🎉 All services started successfully!${NC}"
    echo "================================"
    echo -e "${BLUE}📱 Frontend:${NC} http://localhost:3002"
    echo -e "${BLUE}🔧 Backend:${NC} http://localhost:3001"
    echo -e "${BLUE}📊 Admin Dashboard:${NC} http://localhost:3001/admin/queues"
    echo -e "${BLUE}🌐 LibreTranslate:${NC} http://localhost:5001 (if running)"
    echo ""
    echo -e "${YELLOW}💡 To stop services:${NC}"
    echo "   ./stop-services.sh"
    echo ""
    echo -e "${YELLOW}📝 Note:${NC} Configure translation service in backend/.env"
}

# Run main function
main "$@"
