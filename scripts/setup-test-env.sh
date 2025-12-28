#!/bin/bash

# Setup Test Environment Variables
# This script sets up the minimum required environment variables for testing

echo "🔧 Setting up test environment variables..."

# Required environment variables for testing
export DATABASE_URL="postgresql://testuser:testpassword@localhost:5432/testdb"
export JWT_SECRET_KEY="test-jwt-secret-key-for-local-testing-only-not-for-production-use-32chars"

# Optional environment variables with sensible defaults
export JWT_ALGORITHM="HS256"
export ACCESS_TOKEN_EXPIRE_MINUTES="30"

echo "✅ Test environment variables set:"
echo "   DATABASE_URL: $DATABASE_URL"
echo "   JWT_SECRET_KEY: [HIDDEN]"
echo "   JWT_ALGORITHM: $JWT_ALGORITHM"
echo "   ACCESS_TOKEN_EXPIRE_MINUTES: $ACCESS_TOKEN_EXPIRE_MINUTES"

echo ""
echo "💡 To use these variables in your current shell, run:"
echo "   source ./scripts/setup-test-env.sh"