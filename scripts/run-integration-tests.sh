#!/bin/bash

# Integration Test Runner for LINE Commerce
# This script runs comprehensive integration tests in a clean Docker environment

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

# Function to cleanup test environment
cleanup_test_env() {
    print_status "Cleaning up test environment..."
    docker-compose -f docker-compose.yml -f docker-compose.test.yml down -v --remove-orphans
    docker volume prune -f
}

# Function to wait for service health
wait_for_service_health() {
    local service_name=$1
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be healthy..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f docker-compose.yml -f docker-compose.test.yml ps | grep -q "$service_name.*healthy"; then
            print_success "$service_name is healthy!"
            return 0
        fi
        
        if [ $((attempt % 5)) -eq 0 ]; then
            echo -n " (${attempt}/${max_attempts})"
        else
            echo -n "."
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to become healthy after $((max_attempts * 2)) seconds"
    
    # Show logs for debugging
    print_status "Showing logs for $service_name:"
    docker-compose -f docker-compose.yml -f docker-compose.test.yml logs "$service_name"
    
    return 1
}

# Function to run API health checks
test_api_health() {
    print_status "Testing API health endpoints..."
    
    # Test backend health
    if curl -f -s http://localhost:8001/healthz > /dev/null; then
        print_success "Backend health check passed"
    else
        print_error "Backend health check failed"
        return 1
    fi
    
    # Test frontend accessibility
    if curl -f -s http://localhost:3001 > /dev/null; then
        print_success "Frontend accessibility check passed"
    else
        print_error "Frontend accessibility check failed"
        return 1
    fi
}

# Function to run database connectivity tests
test_database_connectivity() {
    print_status "Testing database connectivity..."
    
    # Test database connection from backend
    if docker-compose -f docker-compose.yml -f docker-compose.test.yml exec -T backend-test python -c "
import asyncio
from app.core.database import engine
from sqlalchemy import text

async def test_db():
    async with engine.begin() as conn:
        result = await conn.execute(text('SELECT 1'))
        assert result.scalar() == 1
    await engine.dispose()
    print('Database connectivity test passed!')

asyncio.run(test_db())
"; then
        print_success "Database connectivity test passed"
    else
        print_error "Database connectivity test failed"
        return 1
    fi
}

# Function to run authentication tests
test_authentication_flow() {
    print_status "Testing authentication flow..."
    
    # Test user registration and login
    if docker-compose -f docker-compose.yml -f docker-compose.test.yml exec -T backend-test python -c "
import asyncio
import httpx
from app.core.config import get_settings

async def test_auth():
    settings = get_settings()
    base_url = 'http://localhost:8000'
    
    async with httpx.AsyncClient() as client:
        # Test registration
        register_data = {
            'email': 'test@example.com',
            'password': 'testpassword123',
            'display_name': 'Test User'
        }
        
        response = await client.post(f'{base_url}/api/auth/register', json=register_data)
        if response.status_code not in [200, 201]:
            print(f'Registration failed: {response.status_code} - {response.text}')
            return False
            
        # Test login
        login_data = {
            'email': 'test@example.com',
            'password': 'testpassword123'
        }
        
        response = await client.post(f'{base_url}/api/auth/login', json=login_data)
        if response.status_code != 200:
            print(f'Login failed: {response.status_code} - {response.text}')
            return False
            
        token = response.json().get('access_token')
        if not token:
            print('No access token received')
            return False
            
        # Test protected endpoint
        headers = {'Authorization': f'Bearer {token}'}
        response = await client.get(f'{base_url}/api/auth/me', headers=headers)
        if response.status_code != 200:
            print(f'Protected endpoint failed: {response.status_code} - {response.text}')
            return False
            
        print('Authentication flow test passed!')
        return True

result = asyncio.run(test_auth())
exit(0 if result else 1)
"; then
        print_success "Authentication flow test passed"
    else
        print_error "Authentication flow test failed"
        return 1
    fi
}

# Function to run CRUD operations tests
test_crud_operations() {
    print_status "Testing CRUD operations..."
    
    if docker-compose -f docker-compose.yml -f docker-compose.test.yml exec -T backend-test python -c "
import asyncio
import httpx

async def test_crud():
    base_url = 'http://localhost:8000'
    
    async with httpx.AsyncClient() as client:
        # First, authenticate to get a token
        login_data = {
            'email': 'test@example.com',
            'password': 'testpassword123'
        }
        
        response = await client.post(f'{base_url}/api/auth/login', json=login_data)
        if response.status_code != 200:
            print('Failed to authenticate for CRUD test')
            return False
            
        token = response.json().get('access_token')
        headers = {'Authorization': f'Bearer {token}'}
        
        # Test item creation
        item_data = {
            'name': 'Test Item',
            'description': 'A test item for integration testing',
            'price': 29.99
        }
        
        response = await client.post(f'{base_url}/api/items', json=item_data, headers=headers)
        if response.status_code not in [200, 201]:
            print(f'Item creation failed: {response.status_code} - {response.text}')
            return False
            
        item = response.json()
        item_id = item.get('id')
        
        # Test item retrieval
        response = await client.get(f'{base_url}/api/items/{item_id}', headers=headers)
        if response.status_code != 200:
            print(f'Item retrieval failed: {response.status_code} - {response.text}')
            return False
            
        # Test item listing
        response = await client.get(f'{base_url}/api/items', headers=headers)
        if response.status_code != 200:
            print(f'Item listing failed: {response.status_code} - {response.text}')
            return False
            
        items = response.json()
        if not isinstance(items, list) or len(items) == 0:
            print('Item listing returned no items')
            return False
            
        print('CRUD operations test passed!')
        return True

result = asyncio.run(test_crud())
exit(0 if result else 1)
"; then
        print_success "CRUD operations test passed"
    else
        print_error "CRUD operations test failed"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    print_status "Running comprehensive integration tests..."
    
    # Start test environment
    print_status "Starting test environment..."
    docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d --build
    
    # Wait for services to be healthy
    wait_for_service_health "line-commerce-postgres-test" || return 1
    wait_for_service_health "line-commerce-backend-test" || return 1
    
    # Give services a moment to fully initialize
    sleep 5
    
    # Run individual test suites
    test_api_health || return 1
    test_database_connectivity || return 1
    test_authentication_flow || return 1
    test_crud_operations || return 1
    
    # Run pytest test suite
    print_status "Running pytest test suite..."
    if docker-compose -f docker-compose.yml -f docker-compose.test.yml run --rm test-runner; then
        print_success "Pytest test suite passed"
    else
        print_error "Pytest test suite failed"
        return 1
    fi
    
    print_success "All integration tests passed! 🎉"
}

# Main script logic
case "${1:-run}" in
    "run")
        echo "🧪 Running LINE Commerce Integration Tests..."
        
        # Trap to ensure cleanup on exit
        trap cleanup_test_env EXIT
        
        if run_all_tests; then
            print_success "Integration tests completed successfully!"
            exit 0
        else
            print_error "Integration tests failed!"
            exit 1
        fi
        ;;
    "clean")
        cleanup_test_env
        print_success "Test environment cleaned up!"
        ;;
    "help"|"-h"|"--help")
        echo "LINE Commerce Integration Test Runner"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  run       Run all integration tests (default)"
        echo "  clean     Clean up test environment"
        echo "  help      Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac