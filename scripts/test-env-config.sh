#!/bin/bash
# Test script for environment configuration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"

    print_status "Running: $test_name"

    if eval "$test_command" > /dev/null 2>&1; then
        print_success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "🧪 Testing Environment Configuration System"
echo "=========================================="

# Test 1: Validation script exists and is executable
run_test "Validation script exists" "test -x ./scripts/validate-env.sh"

# Test 2: Python validation script exists
run_test "Python validation script exists" "test -f ./scripts/validate-env.py"

# Test 3: Environment example files exist
run_test "Root .env.example exists" "test -f .env.example" || true
run_test "Local .env.example exists" "test -f .env.local.example" || true
run_test "Staging .env.example exists" "test -f .env.staging.example" || true
run_test "Production .env.example exists" "test -f .env.production.example" || true
run_test "Frontend .env.example exists" "test -f frontend/.env.example" || true
run_test "Backend .env.example exists" "test -f backend/.env.example" || true

# Test 4: Documentation exists
run_test "Environment documentation exists" "test -f docs/ENVIRONMENT_CONFIGURATION.md" || true

# Test 5: Configuration files exist
run_test "Backend config.py exists" "test -f backend/app/core/config.py" || true
run_test "Frontend config.ts exists" "test -f frontend/lib/config.ts" || true
run_test "Frontend config-server.js exists" "test -f frontend/lib/config-server.js" || true

# Test 6: Validation with missing variables (should fail)
print_status "Testing validation with missing variables (should fail)"
if ./scripts/validate-env.sh > /dev/null 2>&1; then
    print_error "Validation should fail with missing variables"
    ((TESTS_FAILED++))
else
    print_success "Validation correctly fails with missing variables"
    ((TESTS_PASSED++))
fi

# Test 7: Validation with example file (should have warnings)
print_status "Testing validation with example file"
if ./scripts/validate-env.sh -f .env.local.example -e development 2>&1 | grep -q "appears to be a default/weak value"; then
    print_success "Validation correctly identifies weak secrets"
    ((TESTS_PASSED++))
else
    print_error "Validation should identify weak secrets"
    ((TESTS_FAILED++))
fi

# Test 8: GitIgnore properly excludes environment files
run_test "GitIgnore excludes .env files" "grep -q '^\.env$' .gitignore" || true
run_test "GitIgnore excludes secrets/" "grep -q '^secrets/' .gitignore" || true

# Test 9: Docker Compose uses environment variables
run_test "Docker Compose uses JWT_SECRET_KEY" "grep -q 'JWT_SECRET_KEY:' docker-compose.yml" || true
run_test "Docker Compose uses CORS_ORIGINS" "grep -q 'CORS_ORIGINS:' docker-compose.yml" || true

echo ""
echo "=========================================="
echo "Test Results:"
echo "✅ Passed: $TESTS_PASSED"
echo "❌ Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 All environment configuration tests passed!"
    exit 0
else
    echo ""
    echo "💥 Some tests failed. Please check the configuration."
    exit 1
fi
