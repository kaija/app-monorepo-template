#!/bin/bash

# Fix Common Linting Issues
# This script automatically fixes common code quality issues

set -e

echo "🔧 Fixing Common Linting Issues..."
echo "================================="

cd "$(dirname "$0")/../backend"

echo "🎨 Step 1: Running Black formatter..."
python -m black .

echo ""
echo "📋 Step 2: Running isort import sorter..."
python -m isort .

echo ""
echo "🧹 Step 3: Removing unused imports (autoflake)..."
if python -c "import autoflake" 2>/dev/null; then
    autoflake --remove-all-unused-imports --remove-unused-variables --in-place --recursive .
    echo "✅ Unused imports removed"
else
    echo "⚠️  autoflake not installed. Install with: pip install autoflake"
fi

echo ""
echo "🔍 Step 4: Running final checks..."
echo "Black check:"
python -m black --check --diff . || echo "⚠️  Some files still need formatting"

echo ""
echo "isort check:"
python -m isort --check-only --diff . || echo "⚠️  Some imports still need sorting"

echo ""
echo "Flake8 check:"
python -m flake8 . || echo "⚠️  Some linting issues remain"

echo ""
echo "✅ Automatic linting fixes completed!"
echo "💡 Run './scripts/lint-backend.sh' to verify all issues are resolved."