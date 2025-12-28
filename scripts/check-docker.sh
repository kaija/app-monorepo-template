#!/bin/bash

# Check Docker and Docker Compose availability
# This script verifies that Docker and Docker Compose V2 are properly installed

echo "🐳 Checking Docker and Docker Compose..."
echo "========================================"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ Docker is installed: $(docker --version)"

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running"
    echo "Please start Docker Desktop or the Docker daemon"
    exit 1
fi

echo "✅ Docker daemon is running"

# Check Docker Compose V2 (preferred)
if docker compose version &> /dev/null; then
    echo "✅ Docker Compose V2 is available: $(docker compose version)"
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    echo "⚠️  Docker Compose V1 detected: $(docker-compose --version)"
    echo "   Consider upgrading to Docker Compose V2"
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose is not available"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Test basic Docker Compose functionality
echo ""
echo "🧪 Testing Docker Compose functionality..."

if [ -f "docker-compose.yml" ]; then
    echo "✅ Found docker-compose.yml"
    
    # Test config validation
    if $COMPOSE_CMD config &> /dev/null; then
        echo "✅ Docker Compose configuration is valid"
    else
        echo "❌ Docker Compose configuration has errors:"
        $COMPOSE_CMD config
        exit 1
    fi
else
    echo "⚠️  No docker-compose.yml found in current directory"
fi

echo ""
echo "📊 Docker System Information:"
echo "   Docker version: $(docker --version)"
echo "   Compose command: $COMPOSE_CMD"
echo "   Compose version: $($COMPOSE_CMD version --short 2>/dev/null || echo 'Unknown')"

echo ""
echo "✅ Docker environment is ready!"

# Show recommended usage
echo ""
echo "💡 Recommended usage:"
echo "   Use: $COMPOSE_CMD up -d"
echo "   Instead of: docker-compose up -d (if using V1)"