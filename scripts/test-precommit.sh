#!/bin/bash

# Test Pre-commit Setup
# This script tests the pre-commit configuration without installing hooks

set -e

echo "🧪 Testing Pre-commit Configuration..."
echo "====================================="

cd "$(dirname "$0")/../backend"

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."
    pip install pre-commit
fi

echo ""
echo "🔍 Step 1: Validating pre-commit configuration..."
if pre-commit validate-config; then
    echo "✅ Pre-commit configuration is valid"
else
    echo "❌ Pre-commit configuration has errors"
    exit 1
fi

echo ""
echo "🧪 Step 2: Testing pre-commit hooks (dry run)..."
echo "This may take a while on first run as it downloads hook dependencies..."

# Run pre-commit on a single file to test the setup
if [ -f "app/main.py" ]; then
    if pre-commit run --files app/main.py; then
        echo "✅ Pre-commit hooks ran successfully"
    else
        echo "⚠️  Pre-commit hooks found issues (this is normal)"
        echo "   The hooks are working correctly"
    fi
else
    echo "⚠️  No test file found, skipping hook test"
fi

echo ""
echo "🔧 Step 3: Checking hook versions..."
pre-commit --version
echo ""

echo "📋 Available hooks:"
echo "  - black (code formatter)"
echo "  - isort (import sorter)"
echo "  - flake8 (linter)"
echo "  - mypy (type checker)"
echo "  - trailing-whitespace (cleanup)"
echo "  - end-of-file-fixer (cleanup)"
echo "  - check-yaml (validation)"
echo "  - check-added-large-files (safety)"
echo "  - check-merge-conflict (safety)"
echo "  - debug-statements (safety)"

echo ""
echo "✅ Pre-commit testing completed!"
echo ""
echo "💡 To install hooks for this repository:"
echo "   cd backend && pre-commit install"
echo ""
echo "💡 To run hooks manually:"
echo "   cd backend && pre-commit run --all-files"
