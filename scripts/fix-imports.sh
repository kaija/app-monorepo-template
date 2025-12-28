#!/bin/bash

# Fix Import Sorting Issues
# This script automatically fixes import sorting and formatting issues

set -e

echo "📋 Fixing Import Sorting Issues..."
echo "================================="

cd "$(dirname "$0")/../backend"

echo "🔍 Step 1: Running isort to fix import sorting..."
python -m isort .
echo "✅ Import sorting completed"

echo ""
echo "🎨 Step 2: Running Black to ensure consistent formatting..."
python -m black .
echo "✅ Code formatting completed"

echo ""
echo "🔍 Step 3: Verifying fixes..."
echo "Checking isort:"
if python -m isort --check-only --diff .; then
    echo "✅ All imports are properly sorted"
else
    echo "⚠️  Some import issues remain"
fi

echo ""
echo "Checking Black:"
if python -m black --check --diff .; then
    echo "✅ All code is properly formatted"
else
    echo "⚠️  Some formatting issues remain"
fi

echo ""
echo "✅ Import fixing completed!"
echo "💡 Run './scripts/lint-backend.sh' to verify all issues are resolved."
