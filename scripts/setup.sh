#!/bin/bash

# LINE Commerce Monorepo Setup Script
# This script sets up the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🚀 Setting up LINE Commerce Monorepo..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Make is installed (optional but recommended)
if ! command -v make &> /dev/null; then
    print_warning "Make is not installed. You can still use Docker Compose directly."
    print_status "To install Make:"
    print_status "  macOS: brew install make"
    print_status "  Ubuntu/Debian: sudo apt-get install make"
    print_status "  Windows: Install via chocolatey or use WSL"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file from .env.example..."
    cp .env.example .env
    print_warning "Please update .env file with your configuration before running the application."
else
    print_status "Root .env file already exists"
fi

# Create backend .env file if it doesn't exist
if [ ! -f backend/.env ]; then
    print_status "Creating backend/.env file from backend/.env.example..."
    cp backend/.env.example backend/.env
else
    print_status "Backend .env file already exists"
fi

# Create frontend .env.local file if it doesn't exist
if [ ! -f frontend/.env.local ]; then
    print_status "Creating frontend/.env.local file from frontend/.env.example..."
    cp frontend/.env.example frontend/.env.local
else
    print_status "Frontend .env.local file already exists"
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p frontend/components frontend/lib frontend/app
mkdir -p backend/app/api backend/app/core backend/app/models backend/app/schemas backend/app/services backend/app/repositories
mkdir -p backend/alembic/versions
mkdir -p infra/terraform infra/docker
mkdir -p backups

# Make scripts executable
print_status "Making scripts executable..."
chmod +x scripts/*.sh scripts/*.py

print_success "Setup complete!"
print_status ""
print_status "🎯 Next steps:"
print_status "1. Update .env files with your configuration"
print_status "2. Choose one of the following options to start:"
print_status ""
print_status "📋 Option 1 - Using Make (recommended):"
print_status "   make start              # Start development environment"
print_status "   make dev-tools          # Start with additional tools (pgAdmin, Redis, etc.)"
print_status "   make help               # See all available commands"
print_status ""
print_status "📋 Option 2 - Using Docker Compose directly:"
print_status "   docker compose up -d    # Start basic environment"
print_status "   ./scripts/dev-setup.sh  # Start with full setup script"
print_status ""
print_status "📋 Option 3 - Using development scripts:"
print_status "   ./scripts/dev-setup.sh start    # Full development setup"
print_status "   ./scripts/run-integration-tests.sh  # Run tests"
print_status ""
print_status "🌐 Service URLs (after starting):"
print_status "   Frontend:  http://localhost:3000"
print_status "   Backend:   http://localhost:8000"
print_status "   API Docs:  http://localhost:8000/docs"
print_status ""
print_status "📚 Additional resources:"
print_status "   README.md              # Comprehensive documentation"
print_status "   docs/                  # Additional documentation"
print_status "   .kiro/specs/           # Feature specifications"