#!/bin/bash

# Reset Pre-commit Setup
# This script completely resets the pre-commit configuration

set -e

echo "🔄 Resetting Pre-commit Setup..."
echo "==============================="

cd "$(dirname "$0")/../backend"

# Uninstall existing hooks
echo "🗑️  Step 1: Removing existing pre-commit hooks..."
if [ -f ".git/hooks/pre-commit" ]; then
    pre-commit uninstall || true
    echo "✅ Existing hooks removed"
else
    echo "ℹ️  No existing hooks found"
fi

# Clean pre-commit cache
echo ""
echo "🧹 Step 2: Cleaning pre-commit cache..."
pre-commit clean || true
echo "✅ Cache cleaned"

# Remove any test files
echo ""
echo "🧹 Step 3: Cleaning up test files..."
rm -f test_precommit.py
rm -f .pre-commit-config.yaml.bak
echo "✅ Test files cleaned"

# Reset to robust configuration
echo ""
echo "📋 Step 4: Setting up robust configuration..."
if [ -f ".pre-commit-config-robust.yaml" ]; then
    cp .pre-commit-config-robust.yaml .pre-commit-config.yaml
    echo "✅ Robust configuration set as default"
else
    echo "⚠️  Robust configuration not found, using minimal"
    cp .pre-commit-config-minimal.yaml .pre-commit-config.yaml
fi

echo ""
echo "✅ Pre-commit reset completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Run: make setup-precommit"
echo "   2. Test: make test-precommit"
