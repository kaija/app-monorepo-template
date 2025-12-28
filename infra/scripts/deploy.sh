#!/bin/bash

# LINE Commerce Infrastructure Deployment Script
# Usage: ./deploy.sh <environment> [action]
# Example: ./deploy.sh dev plan
# Example: ./deploy.sh prod apply

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$INFRA_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "Usage: $0 <environment> [action]"
    echo ""
    echo "Environments:"
    echo "  dev      - Development environment"
    echo "  staging  - Staging environment"
    echo "  prod     - Production environment"
    echo ""
    echo "Actions:"
    echo "  plan     - Show what Terraform will do (default)"
    echo "  apply    - Apply the Terraform configuration"
    echo "  destroy  - Destroy the infrastructure (use with caution)"
    echo "  init     - Initialize Terraform"
    echo "  validate - Validate Terraform configuration"
    echo "  output   - Show Terraform outputs"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 staging apply"
    echo "  $0 prod output"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi

    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi

    # Check if Vercel CLI is installed (for frontend deployment)
    if ! command -v vercel &> /dev/null; then
        log_warning "Vercel CLI is not installed. Frontend deployment may not work."
        log_info "Install with: npm i -g vercel"
    fi

    log_success "Prerequisites check passed"
}

validate_environment() {
    local env=$1

    if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: $env"
        show_usage
        exit 1
    fi

    # Check if environment file exists
    local env_file="$INFRA_DIR/environments/${env}.tfvars"
    if [[ ! -f "$env_file" ]]; then
        log_error "Environment file not found: $env_file"
        exit 1
    fi

    log_info "Using environment: $env"
}

setup_terraform() {
    local env=$1

    log_info "Setting up Terraform for environment: $env"

    cd "$INFRA_DIR"

    # Initialize Terraform if needed
    if [[ ! -d ".terraform" ]]; then
        log_info "Initializing Terraform..."
        terraform init
    fi

    # Select or create workspace
    if terraform workspace list | grep -q "$env"; then
        log_info "Selecting existing workspace: $env"
        terraform workspace select "$env"
    else
        log_info "Creating new workspace: $env"
        terraform workspace new "$env"
    fi
}

run_terraform() {
    local env=$1
    local action=$2
    local env_file="$INFRA_DIR/environments/${env}.tfvars"

    cd "$INFRA_DIR"

    case $action in
        "init")
            log_info "Initializing Terraform..."
            terraform init
            ;;
        "validate")
            log_info "Validating Terraform configuration..."
            terraform validate
            ;;
        "plan")
            log_info "Planning Terraform deployment for $env..."
            terraform plan -var-file="$env_file" -out="terraform-${env}.tfplan"
            ;;
        "apply")
            log_info "Applying Terraform configuration for $env..."
            if [[ -f "terraform-${env}.tfplan" ]]; then
                terraform apply "terraform-${env}.tfplan"
            else
                log_warning "No plan file found. Running plan and apply..."
                terraform apply -var-file="$env_file"
            fi
            ;;
        "destroy")
            log_warning "This will DESTROY all infrastructure for $env environment!"
            read -p "Are you sure? Type 'yes' to continue: " confirm
            if [[ "$confirm" == "yes" ]]; then
                terraform destroy -var-file="$env_file"
            else
                log_info "Destroy cancelled"
                exit 0
            fi
            ;;
        "output")
            log_info "Showing Terraform outputs for $env..."
            terraform output
            ;;
        *)
            log_error "Unknown action: $action"
            show_usage
            exit 1
            ;;
    esac
}

post_deployment_tasks() {
    local env=$1

    log_info "Running post-deployment tasks for $env..."

    # Get outputs
    local backend_url=$(terraform output -raw backend_api_url 2>/dev/null || echo "")
    local frontend_url=$(terraform output -raw frontend_url 2>/dev/null || echo "")

    if [[ -n "$backend_url" ]]; then
        log_success "Backend API URL: $backend_url"
    fi

    if [[ -n "$frontend_url" ]]; then
        log_success "Frontend URL: $frontend_url"
    fi

    # Health check
    if [[ -n "$backend_url" ]]; then
        log_info "Performing health check..."
        if curl -f -s "${backend_url}/healthz" > /dev/null; then
            log_success "Backend health check passed"
        else
            log_warning "Backend health check failed - this is normal for new deployments"
        fi
    fi
}

# Main script
main() {
    local environment=${1:-}
    local action=${2:-plan}

    if [[ -z "$environment" ]]; then
        log_error "Environment is required"
        show_usage
        exit 1
    fi

    log_info "Starting LINE Commerce infrastructure deployment"
    log_info "Environment: $environment"
    log_info "Action: $action"

    check_prerequisites
    validate_environment "$environment"
    setup_terraform "$environment"
    run_terraform "$environment" "$action"

    if [[ "$action" == "apply" ]]; then
        post_deployment_tasks "$environment"
    fi

    log_success "Deployment script completed successfully"
}

# Run main function with all arguments
main "$@"
