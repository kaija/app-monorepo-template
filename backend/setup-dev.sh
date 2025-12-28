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
pre-commit install

# Run pre-commit on all files to test setup
echo "🧪 Testing pre-commit setup..."
pre-commit run --all-files || {
    echo "⚠️  Pre-commit found issues. Running formatters..."
    black .
    isort .
    echo "✅ Code formatted. Re-running pre-commit..."
    pre-commit run --all-files
}

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "📝 Available commands:"
echo "  - Format code:           ../scripts/format-backend.sh"
echo "  - Lint and check:        ../scripts/lint-backend.sh"
echo "  - Run pre-commit:        pre-commit run --all-files"
echo "  - Update pre-commit:     pre-commit autoupdate"