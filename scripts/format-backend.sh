#!/bin/bash

# Backend Code Formatting Script
# This script automatically formats code without running checks

set -e  # Exit on any error

echo "🎨 Formatting Backend Code..."
echo "============================"

# Change to backend directory
cd "$(dirname "$0")/../backend"

# Check if virtual environment exists
if [[ ! -d "venv" && -z "$VIRTUAL_ENV" ]]; then
    echo "⚠️  No virtual environment detected. Consider running:"
    echo "   python -m venv venv && source venv/bin/activate"
    echo ""
fi

# Install/upgrade dev dependencies
echo "📦 Installing development dependencies..."
pip install -e ".[dev]" --quiet

echo ""
echo "🎨 Formatting code with Black..."
black .

echo ""
echo "📋 Sorting imports with isort..."
isort .

echo ""
echo "✅ Code formatting complete!"
echo "💡 Run './scripts/lint-backend.sh' to check for other issues."
