#!/bin/bash

# Backend Code Linting and Formatting Script
# This script runs all code quality checks and fixes formatting issues

set -e  # Exit on any error

echo "🔍 Running Backend Code Quality Checks..."
echo "========================================"

# Change to backend directory
cd "$(dirname "$0")/../backend"

# Check if virtual environment exists, if not suggest creating one
if [[ ! -d "venv" && -z "$VIRTUAL_ENV" ]]; then
    echo "⚠️  No virtual environment detected. Consider running:"
    echo "   python -m venv venv && source venv/bin/activate"
    echo ""
fi

# Install/upgrade dev dependencies
echo "📦 Installing development dependencies..."
pip install -e ".[dev]" --quiet

echo ""
echo "🎨 Running Black code formatter..."
black --check --diff . || {
    echo "❌ Black formatting issues found. Fixing automatically..."
    black .
    echo "✅ Code formatted with Black"
}

echo ""
echo "📋 Running isort import sorter..."
isort --check-only --diff . || {
    echo "❌ Import sorting issues found. Fixing automatically..."
    isort .
    echo "✅ Imports sorted with isort"
}

echo ""
echo "🔍 Running Flake8 linter..."
flake8 . || {
    echo "❌ Flake8 linting issues found. Please fix manually."
    exit 1
}

echo ""
echo "🔍 Running MyPy type checker..."
mypy app/ || {
    echo "❌ MyPy type checking issues found. Please fix manually."
    exit 1
}

echo ""
echo "✅ All code quality checks passed!"
echo "🚀 Code is ready for submission."
