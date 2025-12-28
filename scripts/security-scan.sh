#!/bin/bash

# Local Security Scanning Script
# Runs security scans that can be executed locally

set -e

echo "🔒 Running Local Security Scans..."
echo "================================="

# Check if we're in the project root
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Create results directory
mkdir -p security-results

echo ""
echo "🔍 Step 1: Filesystem vulnerability scan with Trivy..."
if command -v trivy &> /dev/null; then
    trivy fs . --format table
    trivy fs . --format json --output security-results/trivy-fs.json
    echo "✅ Trivy filesystem scan completed"
else
    echo "⚠️  Trivy not installed. Install with:"
    echo "   # macOS: brew install trivy"
    echo "   # Linux: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
fi

echo ""
echo "🔍 Step 2: Python dependency security scan..."
if [ -f "backend/requirements.txt" ]; then
    cd backend

    # Install safety if not available
    if ! python -c "import safety" 2>/dev/null; then
        echo "📦 Installing safety..."
        pip install safety
    fi

    echo "🔍 Running safety check..."
    safety check --json --output ../security-results/safety-report.json || true
    safety check || echo "⚠️  Safety found some issues (see JSON report for details)"

    cd ..
    echo "✅ Python dependency scan completed"
else
    echo "⚠️  Backend requirements.txt not found, skipping Python dependency scan"
fi

echo ""
echo "🔍 Step 3: JavaScript dependency security scan..."
if [ -f "frontend/package.json" ]; then
    cd frontend

    if [ -f "package-lock.json" ]; then
        echo "🔍 Running npm audit..."
        npm audit --audit-level=moderate --json > ../security-results/npm-audit.json || true
        npm audit --audit-level=moderate || echo "⚠️  npm audit found some issues (see JSON report for details)"
    else
        echo "⚠️  package-lock.json not found, skipping npm audit"
    fi

    cd ..
    echo "✅ JavaScript dependency scan completed"
else
    echo "⚠️  Frontend package.json not found, skipping JavaScript dependency scan"
fi

echo ""
echo "🔍 Step 4: Secret scanning with git-secrets (if available)..."
if command -v git-secrets &> /dev/null; then
    git-secrets --scan || echo "⚠️  git-secrets found potential secrets"
    echo "✅ Secret scanning completed"
else
    echo "⚠️  git-secrets not installed. Install with:"
    echo "   # macOS: brew install git-secrets"
    echo "   # Linux: https://github.com/awslabs/git-secrets#installing-git-secrets"
fi

echo ""
echo "🔍 Step 5: Docker image security scan (if Docker is running)..."
if docker info &> /dev/null; then
    if command -v trivy &> /dev/null; then
        echo "🏗️  Building Docker images..."
        docker build -t line-commerce-backend:security-test ./backend --quiet
        docker build -t line-commerce-frontend:security-test ./frontend --quiet

        echo "🔍 Scanning backend Docker image..."
        trivy image line-commerce-backend:security-test --format json --output security-results/trivy-backend-docker.json
        trivy image line-commerce-backend:security-test || echo "⚠️  Backend Docker image has vulnerabilities"

        echo "🔍 Scanning frontend Docker image..."
        trivy image line-commerce-frontend:security-test --format json --output security-results/trivy-frontend-docker.json
        trivy image line-commerce-frontend:security-test || echo "⚠️  Frontend Docker image has vulnerabilities"

        # Clean up test images
        docker rmi line-commerce-backend:security-test line-commerce-frontend:security-test &> /dev/null || true

        echo "✅ Docker image security scan completed"
    else
        echo "⚠️  Trivy not available for Docker scanning"
    fi
else
    echo "⚠️  Docker not running, skipping Docker image security scan"
fi

echo ""
echo "📊 Security Scan Summary"
echo "======================="
echo "Results saved in: ./security-results/"

if [ -d "security-results" ]; then
    echo "📁 Generated reports:"
    ls -la security-results/ | grep -v "^total" | grep -v "^d" | awk '{print "   " $9}' || echo "   No reports generated"
fi

echo ""
echo "💡 Next steps:"
echo "   1. Review the generated reports in ./security-results/"
echo "   2. Fix any high/critical vulnerabilities"
echo "   3. Consider adding security scanning to your CI/CD pipeline"
echo "   4. Check the GitHub Security tab for automated scan results"

echo ""
echo "✅ Local security scanning completed!"
