#!/bin/bash

# Tranzo Port Checker and Debugger
# This script checks all ports and helps diagnose issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Port configuration
FRONTEND_PORT=3002
BACKEND_PORT=3001
REDIS_PORT=6379
LIBRETRANSLATE_PORT=5001

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a port is open
check_port() {
    local port=$1
    local service_name=$2
    local host=${3:-localhost}
    
    if nc -z "$host" "$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get process using a port
get_port_process() {
    local port=$1
    if command -v lsof &> /dev/null; then
        lsof -ti:$port 2>/dev/null || echo "none"
    else
        echo "lsof not available"
    fi
}

# Check HTTP endpoint
check_http_endpoint() {
    local url=$1
    local service_name=$2
    local timeout=${3:-5}
    
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get HTTP response details
get_http_details() {
    local url=$1
    local timeout=${2:-5}
    
    echo "Response details for $url:"
    echo "------------------------"
    
    # Get status code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time $timeout "$url" 2>/dev/null || echo "000")
    echo "Status Code: $status_code"
    
    # Get response time
    response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time $timeout "$url" 2>/dev/null || echo "timeout")
    echo "Response Time: ${response_time}s"
    
    # Get content type
    content_type=$(curl -s -I --max-time $timeout "$url" 2>/dev/null | grep -i "content-type" | cut -d' ' -f2- || echo "unknown")
    echo "Content Type: $content_type"
    
    # Get first few lines of response
    echo "Response Preview:"
    curl -s --max-time $timeout "$url" 2>/dev/null | head -3 || echo "No response"
    echo ""
}

# Check Docker containers
check_docker_containers() {
    print_header "Docker Container Status"
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not available"
        return 1
    fi
    
    cd backend 2>/dev/null || {
        print_error "Backend directory not found"
        return 1
    }
    
    if [ -f "docker-compose.yml" ]; then
        echo "Docker Compose Services:"
        docker-compose ps 2>/dev/null || print_warning "Docker Compose not running"
        
        echo ""
        echo "Container Health:"
        docker-compose exec redis redis-cli ping 2>/dev/null && print_success "Redis: PONG" || print_error "Redis: Not responding"
        
        if check_http_endpoint "http://localhost:$LIBRETRANSLATE_PORT/languages" "LibreTranslate"; then
            print_success "LibreTranslate: Responding"
        else
            print_error "LibreTranslate: Not responding"
        fi
        
        if check_http_endpoint "http://localhost:$BACKEND_PORT/" "Backend"; then
            print_success "Backend: Responding"
        else
            print_error "Backend: Not responding"
        fi
    else
        print_warning "docker-compose.yml not found"
    fi
    
    cd .. 2>/dev/null || true
}

# Check individual ports
check_individual_ports() {
    print_header "Individual Port Status"
    
    # Frontend (Next.js)
    echo -e "${BLUE}Frontend (Port $FRONTEND_PORT):${NC}"
    if check_port $FRONTEND_PORT "Frontend"; then
        print_success "Port $FRONTEND_PORT is open"
        process=$(get_port_process $FRONTEND_PORT)
        echo "  Process: $process"
        
        if check_http_endpoint "http://localhost:$FRONTEND_PORT" "Frontend"; then
            print_success "Frontend is responding"
            get_http_details "http://localhost:$FRONTEND_PORT"
        else
            print_error "Frontend not responding to HTTP requests"
        fi
    else
        print_error "Port $FRONTEND_PORT is not open"
        echo "  To start: npm run dev"
    fi
    echo ""
    
    # Backend (Express.js)
    echo -e "${BLUE}Backend (Port $BACKEND_PORT):${NC}"
    if check_port $BACKEND_PORT "Backend"; then
        print_success "Port $BACKEND_PORT is open"
        process=$(get_port_process $BACKEND_PORT)
        echo "  Process: $process"
        
        if check_http_endpoint "http://localhost:$BACKEND_PORT" "Backend"; then
            print_success "Backend is responding"
            get_http_details "http://localhost:$BACKEND_PORT"
            
            # Check specific endpoints
            echo "API Endpoints:"
            check_http_endpoint "http://localhost:$BACKEND_PORT/languages" && echo "  ✅ /languages" || echo "  ❌ /languages"
            check_http_endpoint "http://localhost:$BACKEND_PORT/admin/queues" && echo "  ✅ /admin/queues" || echo "  ❌ /admin/queues"
        else
            print_error "Backend not responding to HTTP requests"
        fi
    else
        print_error "Port $BACKEND_PORT is not open"
        echo "  To start: npm run backend:dev (local) or npm run docker:start (Docker)"
    fi
    echo ""
    
    # Redis
    echo -e "${BLUE}Redis (Port $REDIS_PORT):${NC}"
    if check_port $REDIS_PORT "Redis"; then
        print_success "Port $REDIS_PORT is open"
        process=$(get_port_process $REDIS_PORT)
        echo "  Process: $process"
        
        # Test Redis connection
        if command -v redis-cli &> /dev/null; then
            if redis-cli -p $REDIS_PORT ping 2>/dev/null | grep -q "PONG"; then
                print_success "Redis is responding"
                echo "  Redis Info:"
                redis-cli -p $REDIS_PORT info server 2>/dev/null | grep "redis_version" || echo "  Version: Unknown"
            else
                print_error "Redis not responding to commands"
            fi
        else
            print_warning "redis-cli not available for testing"
        fi
    else
        print_error "Port $REDIS_PORT is not open"
        echo "  To start: redis-server (local) or npm run docker:start (Docker)"
    fi
    echo ""
    
    # LibreTranslate
    echo -e "${BLUE}LibreTranslate (Port $LIBRETRANSLATE_PORT):${NC}"
    if check_port $LIBRETRANSLATE_PORT "LibreTranslate"; then
        print_success "Port $LIBRETRANSLATE_PORT is open"
        process=$(get_port_process $LIBRETRANSLATE_PORT)
        echo "  Process: $process"
        
        if check_http_endpoint "http://localhost:$LIBRETRANSLATE_PORT/languages" "LibreTranslate"; then
            print_success "LibreTranslate is responding"
            get_http_details "http://localhost:$LIBRETRANSLATE_PORT/languages"
        else
            print_error "LibreTranslate not responding to HTTP requests"
        fi
    else
        print_error "Port $LIBRETRANSLATE_PORT is not open"
        echo "  To start: libretranslate --host 0.0.0.0 --port 5001 (local) or npm run docker:start (Docker)"
    fi
    echo ""
}

# Check logs for errors
check_logs() {
    print_header "Recent Logs and Errors"
    
    # Check if Docker is running
    if command -v docker &> /dev/null && [ -f "backend/docker-compose.yml" ]; then
        echo "Docker Service Logs (last 20 lines):"
        echo "-----------------------------------"
        
        cd backend 2>/dev/null || return 1
        
        echo -e "${BLUE}Backend Logs:${NC}"
        docker-compose logs --tail=20 translation-backend 2>/dev/null || echo "No backend logs"
        
        echo -e "${BLUE}Redis Logs:${NC}"
        docker-compose logs --tail=10 redis 2>/dev/null || echo "No Redis logs"
        
        echo -e "${BLUE}LibreTranslate Logs:${NC}"
        docker-compose logs --tail=10 libretranslate 2>/dev/null || echo "No LibreTranslate logs"
        
        cd .. 2>/dev/null || true
    else
        echo "Docker not available or not configured"
    fi
    
    # Check system logs for port conflicts
    echo ""
    echo "Port Usage Summary:"
    echo "-------------------"
    if command -v lsof &> /dev/null; then
        echo "Processes using target ports:"
        for port in $FRONTEND_PORT $BACKEND_PORT $REDIS_PORT $LIBRETRANSLATE_PORT; do
            process_info=$(lsof -ti:$port 2>/dev/null | head -1)
            if [ -n "$process_info" ]; then
                process_name=$(ps -p $process_info -o comm= 2>/dev/null || echo "unknown")
                echo "  Port $port: PID $process_info ($process_name)"
            else
                echo "  Port $port: Available"
            fi
        done
    else
        echo "lsof not available for detailed port analysis"
    fi
}

# Provide troubleshooting suggestions
troubleshooting_guide() {
    print_header "Troubleshooting Guide"
    
    echo "Common Issues and Solutions:"
    echo ""
    
    echo "1. Port Already in Use:"
    echo "   - Kill process: kill \$(lsof -ti:PORT_NUMBER)"
    echo "   - Find process: lsof -i:PORT_NUMBER"
    echo ""
    
    echo "2. Services Not Starting:"
    echo "   - Check Docker: docker-compose ps"
    echo "   - Restart Docker: npm run docker:restart"
    echo "   - Check logs: npm run docker:logs"
    echo ""
    
    echo "3. Connection Refused:"
    echo "   - Verify service is running: curl http://localhost:PORT"
    echo "   - Check firewall settings"
    echo "   - Verify environment variables"
    echo ""
    
    echo "4. Redis Issues:"
    echo "   - Test connection: redis-cli ping"
    echo "   - Check Redis config: redis-cli config get '*'"
    echo "   - Restart Redis: docker-compose restart redis"
    echo ""
    
    echo "5. Translation Service Issues:"
    echo "   - Test LibreTranslate: curl http://localhost:5001/languages"
    echo "   - Check Google API credentials in backend/.env"
    echo "   - Verify API quotas and limits"
    echo ""
    
    echo "Quick Commands:"
    echo "   ./check-ports.sh          # Run this script"
    echo "   npm run docker:status     # Check Docker services"
    echo "   npm run docker:logs       # View all logs"
    echo "   ./docker-manager.sh logs [service]  # View specific service logs"
}

# Main execution
main() {
    local command=${1:-"all"}
    
    case "$command" in
        "ports")
            check_individual_ports
            ;;
        "docker")
            check_docker_containers
            ;;
        "logs")
            check_logs
            ;;
        "help")
            troubleshooting_guide
            ;;
        "all"|*)
            print_header "Tranzo Port and Service Checker"
            check_individual_ports
            check_docker_containers
            check_logs
            troubleshooting_guide
            ;;
    esac
}

# Run main function
main "$@"
