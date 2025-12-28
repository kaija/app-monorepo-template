#!/bin/bash

# Setup Terraform Remote State Backend
# This script creates the S3 bucket and DynamoDB table for Terraform state management

set -e

# Configuration
BUCKET_NAME="line-commerce-terraform-state-$(date +%s)"
DYNAMODB_TABLE="terraform-state-lock"
AWS_REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi

    log_success "AWS CLI is configured"
}

create_s3_bucket() {
    log_info "Creating S3 bucket for Terraform state: $BUCKET_NAME"

    # Create bucket
    if aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null; then
        log_success "S3 bucket created: $BUCKET_NAME"
    else
        # If bucket creation fails due to region constraint (us-east-1 doesn't need it)
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
            log_success "S3 bucket created: $BUCKET_NAME"
        else
            log_error "Failed to create S3 bucket"
            exit 1
        fi
    fi

    # Enable versioning
    log_info "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    # Enable server-side encryption
    log_info "Enabling server-side encryption on S3 bucket..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'

    # Block public access
    log_info "Blocking public access on S3 bucket..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

    log_success "S3 bucket configuration completed"
}

create_dynamodb_table() {
    log_info "Creating DynamoDB table for state locking: $DYNAMODB_TABLE"

    # Check if table already exists
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &>/dev/null; then
        log_warning "DynamoDB table already exists: $DYNAMODB_TABLE"
        return 0
    fi

    # Create table
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$AWS_REGION"

    # Wait for table to be active
    log_info "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"

    log_success "DynamoDB table created: $DYNAMODB_TABLE"
}

generate_backend_configs() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local infra_dir="$(dirname "$script_dir")"

    log_info "Generating backend configuration files..."

    # Create backend config for each environment
    for env in dev staging prod; do
        cat > "$infra_dir/backend-${env}.hcl" << EOF
bucket         = "$BUCKET_NAME"
key            = "line-commerce/${env}/terraform.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF
        log_success "Created backend-${env}.hcl"
    done

    # Update terraform.tf with backend configuration
    cat > "$infra_dir/terraform.tf" << EOF
# Terraform configuration file for backend state management

terraform {
  backend "s3" {
    # Backend configuration is loaded from backend-{env}.hcl files
    # Use: terraform init -backend-config=backend-dev.hcl
  }
}

# Backend configuration files:
# - backend-dev.hcl     (development environment)
# - backend-staging.hcl (staging environment)
# - backend-prod.hcl    (production environment)
#
# Usage:
# terraform init -backend-config=backend-dev.hcl
# terraform init -backend-config=backend-staging.hcl
# terraform init -backend-config=backend-prod.hcl
EOF

    log_success "Updated terraform.tf with backend configuration"
}

show_next_steps() {
    log_info "Setup completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "1. Initialize Terraform with backend configuration:"
    echo "   cd infra"
    echo "   terraform init -backend-config=backend-dev.hcl"
    echo ""
    echo "2. Plan your deployment:"
    echo "   ./scripts/deploy.sh dev plan"
    echo ""
    echo "3. Apply your deployment:"
    echo "   ./scripts/deploy.sh dev apply"
    echo ""
    log_info "Backend configuration:"
    echo "   S3 Bucket: $BUCKET_NAME"
    echo "   DynamoDB Table: $DYNAMODB_TABLE"
    echo "   Region: $AWS_REGION"
}

main() {
    log_info "Setting up Terraform remote state backend..."

    check_aws_cli
    create_s3_bucket
    create_dynamodb_table
    generate_backend_configs
    show_next_steps
}

main "$@"
