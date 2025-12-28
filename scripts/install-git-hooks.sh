#!/bin/bash

# Install Git hooks for automatic code formatting
# This script sets up Git hooks to run formatting before commits

set -e

echo "🪝 Installing Git hooks for LINE Commerce..."
echo "==========================================="

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook for LINE Commerce
# Automatically formats backend code before commit

echo "🔍 Running pre-commit checks..."

# Check if backend files are being committed
backend_files=$(git diff --cached --name-only | grep "^backend/" | grep "\.py$" || true)

if [ -n "$backend_files" ]; then
    echo "📝 Backend Python files detected, running formatters..."

    # Change to project root
    cd "$(git rev-parse --show-toplevel)"

    # Run formatters
    ./scripts/format-backend.sh

    # Add formatted files back to staging
    for file in $backend_files; do
        if [ -f "$file" ]; then
            git add "$file"
        fi
    done

    echo "✅ Backend code formatted and re-staged"
fi

echo "✅ Pre-commit checks completed"
EOF

# Make the hook executable
chmod +x .git/hooks/pre-commit

# Create pre-push hook for additional checks
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

# Pre-push hook for LINE Commerce
# Runs full linting before push

echo "🚀 Running pre-push checks..."

# Change to project root
cd "$(git rev-parse --show-toplevel)"

# Check if backend files have been modified
if git diff --name-only HEAD~1 HEAD | grep -q "^backend/.*\.py$"; then
    echo "📝 Backend changes detected, running full lint check..."
    ./scripts/lint-backend.sh
fi

echo "✅ Pre-push checks completed"
EOF

# Make the hook executable
chmod +x .git/hooks/pre-push

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "📝 Installed hooks:"
echo "  - pre-commit:  Automatically formats backend code"
echo "  - pre-push:    Runs full linting before push"
echo ""
echo "💡 To bypass hooks temporarily, use:"
echo "   git commit --no-verify"
echo "   git push --no-verify"
