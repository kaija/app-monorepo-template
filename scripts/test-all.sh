#!/bin/bash

# Comprehensive Test Script
# Runs all tests with proper environment setup

set -e

echo "🧪 Running Comprehensive Test Suite..."
echo "====================================="

# Change to project root
cd "$(dirname "$0")/.."

# Setup test environment variables
echo "🔧 Setting up test environment..."
source ./scripts/setup-test-env.sh

echo ""
echo "🔍 Step 1: Validate migration files..."
./scripts/validate-migrations.sh

echo ""
echo "🗄️  Step 2: Test database operations..."
./scripts/test-database.sh

echo ""
echo "🎨 Step 3: Check code formatting..."
./scripts/lint-backend.sh

echo ""
echo "🧪 Step 4: Run unit tests..."
cd backend
pytest tests/ -v --cov=app --cov-report=term-missing
cd ..

echo ""
echo "🔒 Step 5: Run security scans..."
./scripts/security-scan.sh

echo ""
echo "🎉 All tests completed successfully!"
echo "✅ Migration validation passed"
echo "✅ Database operations passed"
echo "✅ Code formatting passed"
echo "✅ Unit tests passed"
echo "✅ Security scans completed"
