#!/bin/bash

# LINE Commerce Development Environment Setup
# This script sets up and manages the local Docker development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for service to be healthy
wait_for_service() {
    local service_name=$1
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be healthy..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose ps | grep -q "$service_name.*healthy"; then
            print_success "$service_name is healthy!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to become healthy after $((max_attempts * 2)) seconds"
    return 1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to setup environment files
setup_env_files() {
    print_status "Setting up environment files..."
    
    # Root .env file
    if [ ! -f .env ]; then
        print_status "Creating root .env file from .env.example..."
        cp .env.example .env
        print_warning "Please update .env file with your configuration"
    else
        print_status "Root .env file already exists"
    fi
    
    # Backend .env file
    if [ ! -f backend/.env ]; then
        print_status "Creating backend .env file from backend/.env.example..."
        cp backend/.env.example backend/.env
    else
        print_status "Backend .env file already exists"
    fi
    
    # Frontend .env.local file
    if [ ! -f frontend/.env.local ]; then
        print_status "Creating frontend .env.local file from frontend/.env.example..."
        cp frontend/.env.example frontend/.env.local
    else
        print_status "Frontend .env.local file already exists"
    fi
    
    print_success "Environment files are ready!"
}

# Function to build and start services
start_services() {
    print_status "Building and starting Docker services..."
    
    # Build images
    print_status "Building Docker images..."
    docker-compose build --no-cache
    
    # Start services
    print_status "Starting services..."
    docker-compose up -d
    
    # Wait for PostgreSQL to be healthy
    wait_for_service "line-commerce-postgres"
    
    # Wait for backend to be healthy
    wait_for_service "line-commerce-backend"
    
    print_success "All services are running!"
}

# Function to run database migrations
run_migrations() {
    print_status "Running database migrations..."
    
    # Run Alembic migrations in the backend container
    if docker-compose exec -T backend alembic upgrade head; then
        print_success "Database migrations completed!"
    else
        print_warning "Migration failed or Alembic not configured yet"
        print_status "Creating tables from models instead..."
        
        # Fallback: create tables directly from models
        docker-compose exec -T backend python -c "
import asyncio
from app.core.database import engine
from app.models import Base

async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()

asyncio.run(create_tables())
print('Tables created successfully!')
"
        print_success "Database tables created!"
    fi
}

# Function to seed database
seed_database() {
    print_status "Seeding database with sample data..."
    
    if docker-compose exec -T backend python /app/../scripts/seed-db.py; then
        print_success "Database seeded successfully!"
    else
        print_warning "Database seeding failed. You can run it manually later with:"
        print_warning "docker-compose exec backend python /app/../scripts/seed-db.py"
    fi
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    docker-compose ps
    
    echo ""
    print_status "Service URLs:"
    echo "  🌐 Frontend:  http://localhost:3000"
    echo "  🔧 Backend:   http://localhost:8000"
    echo "  📚 API Docs:  http://localhost:8000/docs"
    echo "  🗄️  Database:  postgresql://postgres:postgres@localhost:5432/line_commerce"
    
    echo ""
    print_status "Useful Commands:"
    echo "  📋 View logs:           docker-compose logs -f [service]"
    echo "  🔄 Restart service:     docker-compose restart [service]"
    echo "  🛑 Stop all services:   docker-compose down"
    echo "  🗑️  Reset database:      python scripts/reset-db.py"
    echo "  🌱 Seed database:       python scripts/seed-db.py"
}

# Function to run integration tests
run_tests() {
    print_status "Running integration tests..."
    
    # Ensure services are running
    if ! docker-compose ps | grep -q "line-commerce-backend.*Up"; then
        print_error "Backend service is not running. Please start services first."
        exit 1
    fi
    
    # Run backend tests
    print_status "Running backend tests..."
    docker-compose exec -T backend python -m pytest tests/ -v
    
    # Run frontend tests (if they exist)
    if [ -d "frontend/tests" ] || [ -f "frontend/package.json" ]; then
        print_status "Running frontend tests..."
        docker-compose exec -T frontend npm test -- --watchAll=false
    fi
    
    print_success "All tests completed!"
}

# Function to clean up
cleanup() {
    print_status "Cleaning up Docker resources..."
    
    # Stop and remove containers
    docker-compose down -v
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes
    docker volume prune -f
    
    print_success "Cleanup completed!"
}

# Main script logic
case "${1:-start}" in
    "start")
        echo "🚀 Starting LINE Commerce Development Environment..."
        check_prerequisites
        setup_env_files
        start_services
        run_migrations
        seed_database
        show_status
        ;;
    "stop")
        print_status "Stopping services..."
        docker-compose down
        print_success "Services stopped!"
        ;;
    "restart")
        print_status "Restarting services..."
        docker-compose restart
        show_status
        ;;
    "status")
        show_status
        ;;
    "logs")
        service=${2:-}
        if [ -n "$service" ]; then
            docker-compose logs -f "$service"
        else
            docker-compose logs -f
        fi
        ;;
    "test")
        run_tests
        ;;
    "reset")
        print_warning "This will reset the database and remove all data!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose exec -T backend python /app/../scripts/reset-db.py
            seed_database
        else
            print_status "Reset cancelled."
        fi
        ;;
    "clean")
        print_warning "This will stop all services and remove Docker resources!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup
        else
            print_status "Cleanup cancelled."
        fi
        ;;
    "help"|"-h"|"--help")
        echo "LINE Commerce Development Environment Manager"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  start     Start the development environment (default)"
        echo "  stop      Stop all services"
        echo "  restart   Restart all services"
        echo "  status    Show service status and URLs"
        echo "  logs      Show logs for all services or specific service"
        echo "  test      Run integration tests"
        echo "  reset     Reset database (removes all data)"
        echo "  clean     Stop services and clean up Docker resources"
        echo "  help      Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 start          # Start development environment"
        echo "  $0 logs backend   # Show backend logs"
        echo "  $0 test           # Run all tests"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac