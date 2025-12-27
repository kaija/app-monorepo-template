#!/bin/bash
# Environment validation script wrapper

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
ENVIRONMENT="development"
ENV_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --environment ENV    Environment to validate (development, staging, production)"
            echo "  -f, --env-file FILE      Path to .env file to validate"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Validate current environment"
            echo "  $0 -e production                     # Validate for production"
            echo "  $0 -f .env.local -e development      # Validate specific .env file"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

print_status "Starting environment validation..."
print_status "Environment: $ENVIRONMENT"

if [[ -n "$ENV_FILE" ]]; then
    print_status "Using env file: $ENV_FILE"
    
    if [[ ! -f "$ENV_FILE" ]]; then
        print_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
fi

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not installed"
    exit 1
fi

# Run the Python validation script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/validate-env.py"

if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    print_error "Validation script not found: $PYTHON_SCRIPT"
    exit 1
fi

# Build command
CMD="python3 $PYTHON_SCRIPT --environment $ENVIRONMENT"
if [[ -n "$ENV_FILE" ]]; then
    CMD="$CMD --env-file $ENV_FILE"
fi

# Run validation
if eval $CMD; then
    print_success "Environment validation completed successfully!"
    exit 0
else
    print_error "Environment validation failed!"
    echo ""
    print_status "Common fixes:"
    echo "  1. Copy .env.example to .env and update values"
    echo "  2. Generate secure secrets using: openssl rand -hex 32"
    echo "  3. Ensure all required environment variables are set"
    echo "  4. Use HTTPS URLs in production environments"
    exit 1
fi