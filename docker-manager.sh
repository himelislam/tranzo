#!/bin/bash

# Tranzo Docker Management Script
# Manages the complete Docker setup for Tranzo application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="backend"
COMPOSE_FILE="$BACKEND_DIR/docker-compose.yml"

# Function to print colored output
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

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available"
        exit 1
    fi
    
    print_success "Docker and Docker Compose are available"
}

# Build the Docker images
build_images() {
    print_header "Building Docker Images"
    
    cd "$BACKEND_DIR"
    
    print_status "Building translation-backend image..."
    docker-compose build --no-cache translation-backend
    
    print_success "Docker images built successfully"
    cd ..
}

# Start all services
start_services() {
    print_header "Starting Tranzo Services with Docker"
    
    cd "$BACKEND_DIR"
    
    print_status "Starting services in detached mode..."
    docker-compose up -d
    
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    print_status "Checking service health..."
    
    # Check Redis
    if docker-compose exec redis redis-cli ping | grep -q "PONG"; then
        print_success "Redis is healthy"
    else
        print_warning "Redis might not be ready yet"
    fi
    
    # Check LibreTranslate
    if curl -s http://localhost:5001/languages > /dev/null; then
        print_success "LibreTranslate is healthy"
    else
        print_warning "LibreTranslate might not be ready yet"
    fi
    
    # Check Backend
    if curl -s http://localhost:3001/languages > /dev/null; then
        print_success "Backend is healthy"
    else
        print_warning "Backend might not be ready yet"
    fi
    
    print_success "All services started successfully"
    cd ..
}

# Stop all services
stop_services() {
    print_header "Stopping Tranzo Services"
    
    cd "$BACKEND_DIR"
    
    print_status "Stopping all services..."
    docker-compose down
    
    print_success "All services stopped"
    cd ..
}

# Show service status
show_status() {
    print_header "Service Status"
    
    cd "$BACKEND_DIR"
    
    print_status "Container status:"
    docker-compose ps
    
    echo ""
    print_status "Service URLs:"
    echo "  🔧 Backend API: http://localhost:3001"
    echo "  📊 Admin Dashboard: http://localhost:3001/admin/queues"
    echo "  🌐 LibreTranslate: http://localhost:5001"
    echo "  📦 Redis: localhost:6379"
    
    cd ..
}

# Show logs
show_logs() {
    local service=${1:-""}
    
    cd "$BACKEND_DIR"
    
    if [ -n "$service" ]; then
        print_header "Logs for $service"
        docker-compose logs -f "$service"
    else
        print_header "All Service Logs"
        docker-compose logs -f
    fi
    
    cd ..
}

# Clean up everything
cleanup() {
    print_header "Cleaning Up Docker Resources"
    
    cd "$BACKEND_DIR"
    
    print_status "Stopping and removing containers..."
    docker-compose down -v
    
    print_status "Removing images..."
    docker-compose down --rmi all
    
    print_status "Removing unused Docker resources..."
    docker system prune -f
    
    print_success "Cleanup completed"
    cd ..
}

# Restart services
restart_services() {
    print_header "Restarting Tranzo Services"
    
    stop_services
    sleep 2
    start_services
}

# Update services
update_services() {
    print_header "Updating Tranzo Services"
    
    cd "$BACKEND_DIR"
    
    print_status "Pulling latest images..."
    docker-compose pull
    
    print_status "Rebuilding backend..."
    docker-compose build --no-cache translation-backend
    
    print_status "Restarting services..."
    docker-compose up -d
    
    print_success "Services updated successfully"
    cd ..
}

# Show help
show_help() {
    echo "Tranzo Docker Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build       Build Docker images"
    echo "  start       Start all services"
    echo "  stop        Stop all services"
    echo "  restart     Restart all services"
    echo "  status      Show service status"
    echo "  logs [svc]  Show logs (optionally for specific service)"
    echo "  update      Update and restart services"
    echo "  cleanup     Stop services and clean up Docker resources"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start all services"
    echo "  $0 logs translation-backend # Show backend logs"
    echo "  $0 status                   # Check service status"
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case "$command" in
        "build")
            check_docker
            build_images
            ;;
        "start")
            check_docker
            start_services
            show_status
            ;;
        "stop")
            check_docker
            stop_services
            ;;
        "restart")
            check_docker
            restart_services
            show_status
            ;;
        "status")
            check_docker
            show_status
            ;;
        "logs")
            check_docker
            show_logs "$2"
            ;;
        "update")
            check_docker
            update_services
            show_status
            ;;
        "cleanup")
            check_docker
            cleanup
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
