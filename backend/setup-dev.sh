#!/bin/bash

# Backend Development Environment Setup
# This script sets up pre-commit hooks and development tools

set -e

echo "🛠️  Setting up Backend Development Environment..."
echo "=============================================="

# Install development dependencies
echo "📦 Installing development dependencies..."
pip install -e ".[dev]"

# Install pre-commit
echo "🪝 Installing pre-commit..."
pip install pre-commit

# Install pre-commit hooks
echo "🔧 Setting up pre-commit hooks..."
if pre-commit install; then
    echo "✅ Pre-commit hooks installed successfully"
else
    echo "⚠️  Pre-commit hook installation had issues, but continuing..."
fi

# Test pre-commit setup (but don't fail if it has issues)
echo "🧪 Testing pre-commit setup..."
if pre-commit run --all-files; then
    echo "✅ Pre-commit hooks working correctly"
else
    echo "⚠️  Pre-commit found issues. Running formatters..."
    black .
    isort .
    echo "✅ Code formatted. Pre-commit should work now."
fi

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "📝 Available commands:"
echo "  - Format code:           ../scripts/format-backend.sh"
echo "  - Lint and check:        ../scripts/lint-backend.sh"
echo "  - Run pre-commit:        pre-commit run --all-files"
echo "  - Update pre-commit:     pre-commit autoupdate"
