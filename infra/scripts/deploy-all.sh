#!/bin/bash

# Combined deployment script for Basic Item CRUD App (Backend + Frontend) on AWS
set -Eeuo pipefail

# Store the script directory and base paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/../terraform" && pwd)"
BACKEND_DIR="$TERRAFORM_DIR/tf-backend"
FRONTEND_DIR="$TERRAFORM_DIR/tf-frontend"
FRONTEND_SRC_DIR="$(cd "$SCRIPT_DIR/../../frontend" && pwd)"

# Helpful error message
trap 'echo -e "\n[ERROR] Failed at line $LINENO: $BASH_COMMAND"; if [[ -t 0 ]]; then echo -e "\n${YELLOW}Press any key to close this terminal...${NC}"; read -n 1 -s; fi; exit 1' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Check if required tools are installed
check_dependencies() {
    print_section "Checking Dependencies"
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    print_status "All dependencies are installed."
}

# Parse command line arguments
BACKEND_ONLY=false
FRONTEND_ONLY=false
SKIP_CONFIRM=false
SKIP_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --backend-only)
            BACKEND_ONLY=true
            shift
            ;;
        --frontend-only)
            FRONTEND_ONLY=true
            shift
            ;;
        --skip-confirm)
            SKIP_CONFIRM=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --backend-only     Deploy only backend infrastructure"
            echo "  --frontend-only    Deploy only frontend (requires backend to exist)"
            echo "  --skip-confirm     Skip confirmation prompts"
            echo "  --skip-docker      Skip Docker build/push (use existing image)"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                     # Full deployment (backend + frontend)"
            echo "  $0 --backend-only      # Backend only"
            echo "  $0 --frontend-only     # Frontend only"
            echo "  $0 --skip-confirm      # No prompts"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate conflicting options
if [ "$BACKEND_ONLY" = true ] && [ "$FRONTEND_ONLY" = true ]; then
    print_error "Cannot specify both --backend-only and --frontend-only"
    exit 1
fi

echo -e "${GREEN}🚀 Starting deployment of Basic Item CRUD App${NC}"
if [ "$BACKEND_ONLY" = true ]; then
    echo -e "${BLUE}📦 Backend deployment only${NC}"
elif [ "$FRONTEND_ONLY" = true ]; then
    echo -e "${BLUE}🌐 Frontend deployment only${NC}"
else
    echo -e "${BLUE}📦🌐 Full deployment (Backend + Frontend)${NC}"
fi

# Check if terraform.tfvars exists in tf-backend
if [ ! -f "$BACKEND_DIR/terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found in tf-backend. Creating from example..."
    if [ -f "$BACKEND_DIR/terraform.tfvars.example" ]; then
        cp "$BACKEND_DIR/terraform.tfvars.example" "$BACKEND_DIR/terraform.tfvars"
        print_warning "Please edit tf-backend/terraform.tfvars with your values before continuing"
        exit 1
    else
        print_error "terraform.tfvars.example not found. Please create terraform.tfvars manually."
        exit 1
    fi
fi

# Get configuration from terraform.tfvars
AWS_REGION=$(grep 'aws_region' "$BACKEND_DIR/terraform.tfvars" | cut -d'"' -f2)
APP_NAME=$(grep 'app_name' "$BACKEND_DIR/terraform.tfvars" | cut -d'"' -f2)
ENVIRONMENT=$(grep 'environment' "$BACKEND_DIR/terraform.tfvars" | cut -d'"' -f2)

print_section "Configuration"
echo "  Region: $AWS_REGION"
echo "  App Name: $APP_NAME"
echo "  Environment: $ENVIRONMENT"

# Function to cleanup orphaned API Gateway resources
cleanup_orphaned_api_gateway() {
    print_section "Checking for Orphaned API Gateway Resources"
    
    local api_name="${APP_NAME}-${ENVIRONMENT}-api"
    
    # Check if API Gateway exists
    print_status "Looking for API Gateway: $api_name"
    local api_id=$(aws apigateway get-rest-apis --region "$AWS_REGION" --query "items[?name=='$api_name'].id" --output text 2>/dev/null || echo "")
    
    if [ -z "$api_id" ]; then
        print_status "No existing API Gateway found. Proceeding with fresh deployment."
        return 0
    fi
    
    print_warning "Found existing API Gateway: $api_id"
    
    # Check if the API Gateway is in Terraform state
    cd "$BACKEND_DIR"
    terraform init -input=false >/dev/null 2>&1 || true
    
    local in_state=$(terraform state list 2>/dev/null | grep "aws_api_gateway_rest_api.main" || echo "")
    
    if [ -z "$in_state" ]; then
        print_warning "API Gateway exists in AWS but not in Terraform state!"
        echo ""
        echo -e "${YELLOW}Options:${NC}"
        echo "  1) Import existing API Gateway into Terraform (recommended)"
        echo "  2) Delete existing API Gateway and create new one"
        echo "  3) Cancel deployment"
        echo ""
        
        if [[ -t 0 ]] && [ "$SKIP_CONFIRM" = false ]; then
            echo -e "${CYAN}Enter your choice (1/2/3): ${NC}"
            read -r choice
            
            case $choice in
                1)
                    print_status "Importing existing API Gateway..."
                    terraform import aws_api_gateway_rest_api.main "$api_id" || {
                        print_error "Failed to import API Gateway"
                        exit 1
                    }
                    
                    # Try to import the stage if it exists
                    print_status "Checking for existing stage..."
                    if aws apigateway get-stage --rest-api-id "$api_id" --stage-name "$ENVIRONMENT" --region "$AWS_REGION" >/dev/null 2>&1; then
                        print_status "Found existing stage, importing..."
                        terraform import aws_api_gateway_stage.main "${api_id}/${ENVIRONMENT}" || {
                            print_warning "Could not import stage, will recreate"
                        }
                    fi
                    
                    print_success "Imported existing API Gateway resources"
                    ;;
                2)
                    print_warning "Deleting existing API Gateway..."
                    
                    # Delete stages first
                    print_status "Deleting stages..."
                    for stage in $(aws apigateway get-stages --rest-api-id "$api_id" --region "$AWS_REGION" --query 'item[].stageName' --output text 2>/dev/null); do
                        print_status "Deleting stage: $stage"
                        aws apigateway delete-stage --rest-api-id "$api_id" --stage-name "$stage" --region "$AWS_REGION" 2>/dev/null || true
                    done
                    
                    # Delete the API Gateway
                    print_status "Deleting API Gateway..."
                    aws apigateway delete-rest-api --rest-api-id "$api_id" --region "$AWS_REGION" || {
                        print_error "Failed to delete API Gateway"
                        exit 1
                    }
                    
                    print_success "Deleted existing API Gateway"
                    sleep 5  # Wait for AWS to fully delete
                    ;;
                3)
                    print_error "Deployment cancelled by user"
                    exit 0
                    ;;
                *)
                    print_error "Invalid choice. Deployment cancelled."
                    exit 1
                    ;;
            esac
        else
            # Non-interactive mode: try to import
            print_status "Non-interactive mode: attempting to import..."
            terraform import aws_api_gateway_rest_api.main "$api_id" 2>/dev/null || true
            
            if aws apigateway get-stage --rest-api-id "$api_id" --stage-name "$ENVIRONMENT" --region "$AWS_REGION" >/dev/null 2>&1; then
                terraform import aws_api_gateway_stage.main "${api_id}/${ENVIRONMENT}" 2>/dev/null || true
            fi
        fi
    else
        print_status "API Gateway is properly tracked in Terraform state"
        
        # Check if stage exists but is not in state
        local stage_in_state=$(terraform state list 2>/dev/null | grep "aws_api_gateway_stage.main" || echo "")
        
        if [ -z "$stage_in_state" ]; then
            print_warning "API Gateway stage might be orphaned, checking..."
            
            if aws apigateway get-stage --rest-api-id "$api_id" --stage-name "$ENVIRONMENT" --region "$AWS_REGION" >/dev/null 2>&1; then
                print_status "Found orphaned stage, importing..."
                terraform import aws_api_gateway_stage.main "${api_id}/${ENVIRONMENT}" || {
                    print_warning "Could not import stage, attempting to delete..."
                    aws apigateway delete-stage --rest-api-id "$api_id" --stage-name "$ENVIRONMENT" --region "$AWS_REGION" 2>/dev/null || true
                }
            fi
        fi
    fi
    
    print_status "Cleanup check complete"
}

# Backend deployment function
deploy_backend() {
    print_section "Backend Deployment"
    
    # Cleanup any orphaned API Gateway resources
    cleanup_orphaned_api_gateway
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    cd "$BACKEND_DIR"
    terraform init

    # Plan deployment
    print_status "Planning deployment..."
    terraform plan -out=tfplan

    # Review plan and confirm
    if [ "$SKIP_CONFIRM" = false ]; then
        echo -e "\n${YELLOW}📋 Please review the Terraform plan above.${NC}"
        echo -e "${YELLOW}Do you want to proceed with applying these changes? (y/N):${NC}"

        if [[ -t 0 ]]; then
            read -r CONFIRM
            if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                print_error "Deployment cancelled by user."
                print_warning "Cleaning up plan file..."
                rm -f tfplan
                exit 0
            fi
        else
            print_warning "Non-interactive mode detected. Proceeding automatically..."
        fi
    fi

    # Create ECR repository first
    print_status "Creating ECR repository..."
    terraform apply -target=aws_ecr_repository.main -target=aws_ecr_lifecycle_policy.main -auto-approve

    # Get ECR repository URL
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url)

    if [ "$SKIP_DOCKER" = false ]; then
        print_status "Building and pushing Docker image..."
        
        # Login to ECR
        print_status "Logging in to ECR..."
        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL

        # Build Docker image
        print_status "Building Docker image..."
        BACKEND_SRC_DIR="$(cd "$SCRIPT_DIR/../../backend" && pwd)"
        docker build --platform linux/amd64 --provenance=false -t $APP_NAME "$BACKEND_SRC_DIR"

        # Tag image
        print_status "Tagging image..."
        docker tag $APP_NAME:latest $ECR_REPO_URL:latest

        # Push image
        print_status "Pushing image to ECR..."
        docker push $ECR_REPO_URL:latest
    else
        print_warning "Skipping Docker build/push (using existing image)"
    fi

    # Apply the full infrastructure
    print_status "Applying full infrastructure..."
    terraform apply -auto-approve

    # Get outputs
    API_URL=$(terraform output -raw api_gateway_invoke_url)
    LAMBDA_URL=$(terraform output -raw lambda_function_url 2>/dev/null || echo "N/A")

    print_status "Backend deployment complete!"
    echo "  API Gateway URL: $API_URL"
    if [ "$LAMBDA_URL" != "N/A" ]; then
        echo "  Lambda Function URL: $LAMBDA_URL"
    fi

    # Clean up
    rm -f tfplan
}

# Frontend deployment function
deploy_frontend() {
    print_section "Frontend Deployment"
    
    # Check if backend exists
    if [ ! -f "$BACKEND_DIR/terraform.tfstate" ]; then
        print_error "Backend Terraform state file not found. Please deploy backend first."
        exit 1
    fi

    # Get API Gateway ID from backend
    print_status "Getting backend outputs..."
    cd "$BACKEND_DIR"
    API_GATEWAY_ID=$(terraform output -raw api_gateway_id 2>/dev/null || echo "")
    
    # Initialize frontend terraform
    print_status "Initializing frontend Terraform..."
    cd "$FRONTEND_DIR"
    terraform init
    
    # Set API Gateway ID if available
    if [ -n "$API_GATEWAY_ID" ]; then
        print_status "Configuring frontend with API Gateway ID: $API_GATEWAY_ID"
        export TF_VAR_api_gateway_id="$API_GATEWAY_ID"
    fi

    # Get Terraform outputs
    print_status "Getting Terraform outputs..."
    
    S3_BUCKET=$(terraform output -raw frontend_s3_bucket)
    CLOUDFRONT_DOMAIN=$(terraform output -raw frontend_cloudfront_domain)
    CLOUDFRONT_URL=$(terraform output -raw frontend_cloudfront_url)
    CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw frontend_cloudfront_distribution_id)
    
    if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_DOMAIN" ] || [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        print_error "Failed to get Terraform outputs. Please check your Terraform configuration."
        exit 1
    fi
    
    print_status "S3 Bucket: $S3_BUCKET"
    print_status "CloudFront Domain: $CLOUDFRONT_DOMAIN"
    print_status "CloudFront Distribution ID: $CLOUDFRONT_DISTRIBUTION_ID"
    print_status "CloudFront URL: $CLOUDFRONT_URL"

    # Upload files to S3
    print_status "Uploading frontend files to S3..."
    
    if [ ! -d "$FRONTEND_SRC_DIR" ]; then
        print_error "Frontend directory not found at $FRONTEND_SRC_DIR"
        exit 1
    fi
    
    # Upload all files with appropriate content types
    aws s3 sync "$FRONTEND_SRC_DIR" "s3://$S3_BUCKET" \
        --delete \
        --cache-control "max-age=31536000" \
        --exclude "*.html" \
        --exclude "*.css" \
        --exclude "*.js"
    
    # Upload HTML files with no cache
    aws s3 sync "$FRONTEND_SRC_DIR" "s3://$S3_BUCKET" \
        --cache-control "no-cache" \
        --include "*.html"
    
    # Upload CSS and JS files with shorter cache
    aws s3 sync "$FRONTEND_SRC_DIR" "s3://$S3_BUCKET" \
        --cache-control "max-age=3600" \
        --include "*.css" \
        --include "*.js"
    
    print_status "Files uploaded successfully to S3."

    # Invalidate CloudFront cache
    print_status "Invalidating CloudFront cache..."
    
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*" \
        --query "Invalidation.Id" \
        --output text)
    
    print_status "CloudFront invalidation created: $INVALIDATION_ID"
    print_status "Cache invalidation is in progress. It may take a few minutes to complete."

    print_status "Frontend deployment complete!"
    echo "  Frontend URL: $CLOUDFRONT_URL"
}

# Main deployment logic
main() {
    check_dependencies

    if [ "$FRONTEND_ONLY" = true ]; then
        deploy_frontend
    elif [ "$BACKEND_ONLY" = true ]; then
        deploy_backend
    else
        # Full deployment
        deploy_backend
        deploy_frontend
    fi

    print_section "Deployment Summary"
    
    if [ "$FRONTEND_ONLY" = false ]; then
        echo -e "${GREEN}✅ Backend deployed successfully!${NC}"
        echo "  API Gateway URL: $(cd "$BACKEND_DIR" && terraform output -raw api_gateway_invoke_url)"
    fi
    
    if [ "$BACKEND_ONLY" = false ]; then
        echo -e "${GREEN}✅ Frontend deployed successfully!${NC}"
        echo "  Frontend URL: $(cd "$FRONTEND_DIR" && terraform output -raw frontend_cloudfront_url)"
    fi

    echo -e "\n${GREEN}🎉 Deployment finished successfully!${NC}"
    
    if [ "$FRONTEND_ONLY" = false ] && [ "$BACKEND_ONLY" = false ]; then
        echo -e "${BLUE}🌐 Your full-stack application is now live!${NC}"
        echo -e "${BLUE}   Frontend: $(cd "$FRONTEND_DIR" && terraform output -raw frontend_cloudfront_url)${NC}"
        echo -e "${BLUE}   API: $(cd "$BACKEND_DIR" && terraform output -raw api_gateway_invoke_url)${NC}"
    fi

    # Keep terminal open for review
    if [ "$SKIP_CONFIRM" = false ] && [[ -t 0 ]]; then
        echo -e "\n${YELLOW}Press any key to continue or Ctrl+C to exit...${NC}"
        read -n 1 -s
        echo -e "${GREEN}Deployment complete. Terminal will remain open.${NC}"
        exec bash
    else
        echo -e "${GREEN}Deployment complete.${NC}"
    fi
}

# Run main function
main "$@"
