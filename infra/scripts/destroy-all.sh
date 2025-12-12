#!/bin/bash

# Comprehensive destruction script for Basic Item CRUD App infrastructure on AWS
set -Eeuo pipefail

# Store the script directory and base paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/../terraform" && pwd)"
BACKEND_DIR="$TERRAFORM_DIR/tf-backend"
FRONTEND_DIR="$TERRAFORM_DIR/tf-frontend"

# Helpful error message
trap 'echo -e "\n[ERROR] Failed at line $LINENO: $BASH_COMMAND"; if [[ -t 0 ]]; then echo -e "\n${YELLOW}Press any key to close this terminal...${NC}"; read -n 1 -s; fi; exit 1' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_danger() {
    echo -e "${RED}[DANGER]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to show ECR repository contents
show_ecr_contents() {
    local repo_name="$1"
    local region="$2"
    
    print_section "ECR Repository Contents"
    echo -e "${CYAN}Repository: $repo_name${NC}"
    echo -e "${CYAN}Region: $region${NC}"
    echo ""
    
    # List images in the repository
    print_status "Listing images in ECR repository..."
    if aws ecr list-images --repository-name "$repo_name" --region "$region" --query 'imageIds[*].[imageTag,imagePushedAt]' --output table 2>/dev/null; then
        echo ""
        
        # Get image count
        local image_count=$(aws ecr list-images --repository-name "$repo_name" --region "$region" --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
        
        if [ "$image_count" -gt 0 ]; then
            print_warning "Found $image_count image(s) in the repository"
            echo ""
            print_warning "Images will be PERMANENTLY DELETED along with the repository!"
        else
            print_status "Repository is empty (no images found)"
        fi
    else
        print_warning "Could not list images in repository (may not exist or no access)"
    fi
}

# Function to confirm ECR repository deletion
confirm_ecr_deletion() {
    local repo_name="$1"
    local region="$2"
    
    echo ""
    print_danger "⚠️  ECR REPOSITORY DELETION CONFIRMATION ⚠️"
    echo -e "${RED}This will PERMANENTLY DELETE the ECR repository: $repo_name${NC}"
    echo -e "${RED}All Docker images in this repository will be LOST FOREVER!${NC}"
    echo ""
    
    # Show repository contents
    show_ecr_contents "$repo_name" "$region"
    
    echo ""
    echo -e "${YELLOW}Are you absolutely sure you want to delete this ECR repository?${NC}"
    echo -e "${YELLOW}This action CANNOT be undone!${NC}"
    echo ""
    echo -e "${CYAN}Type 'DELETE ECR' (exactly as shown) to confirm:${NC}"
    
    if [[ -t 0 ]]; then
        read -r confirmation
        if [ "$confirmation" = "DELETE ECR" ]; then
            print_status "ECR deletion confirmed by user"
            return 0
        else
            print_warning "ECR deletion cancelled by user"
            return 1
        fi
    else
        print_warning "Non-interactive mode detected. Skipping ECR deletion for safety."
        return 1
    fi
}

# Function to delete ECR repository
delete_ecr_repository() {
    local repo_name="$1"
    local region="$2"
    
    print_section "Deleting ECR Repository"
    
    # Check if repository exists
    if aws ecr describe-repositories --repository-names "$repo_name" --region "$region" >/dev/null 2>&1; then
        print_status "ECR repository '$repo_name' found"
        
        # Confirm deletion
        if confirm_ecr_deletion "$repo_name" "$region"; then
            print_status "Deleting ECR repository..."
            
            # Delete all images first
            print_status "Deleting all images in repository..."
            aws ecr list-images --repository-name "$repo_name" --region "$region" --query 'imageIds[*]' --output json | \
            jq -r '.[] | .imageDigest' | \
            xargs -I {} aws ecr batch-delete-image --repository-name "$repo_name" --region "$region" --image-ids imageDigest={} 2>/dev/null || true
            
            # Delete the repository
            print_status "Deleting ECR repository..."
            aws ecr delete-repository --repository-name "$repo_name" --region "$region" --force
            
            print_success "ECR repository '$repo_name' deleted successfully"
        else
            print_warning "Skipping ECR repository deletion"
        fi
    else
        print_status "ECR repository '$repo_name' not found or already deleted"
    fi
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
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. Some features may not work properly."
        print_warning "Please install jq for better JSON handling: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    fi
    
    print_status "All required dependencies are installed."
}

# Parse command line arguments
BACKEND_ONLY=false
FRONTEND_ONLY=false
SKIP_CONFIRM=false
SKIP_ECR=false
FORCE=false

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
        --skip-ecr)
            SKIP_ECR=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --backend-only     Destroy only backend infrastructure"
            echo "  --frontend-only    Destroy only frontend infrastructure"
            echo "  --skip-confirm     Skip confirmation prompts"
            echo "  --skip-ecr         Skip ECR repository deletion"
            echo "  --force            Force destruction without confirmation"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                     # Full destruction (backend + frontend + ECR)"
            echo "  $0 --backend-only      # Backend only (includes ECR)"
            echo "  $0 --frontend-only     # Frontend only"
            echo "  $0 --skip-confirm      # No prompts"
            echo "  $0 --force             # Force destruction"
            echo ""
            echo "⚠️  WARNING: This will permanently destroy your infrastructure! ⚠️"
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

echo -e "${RED}💀 DESTRUCTION SCRIPT FOR BASIC ITEM CRUD APP 💀${NC}"
if [ "$BACKEND_ONLY" = true ]; then
    echo -e "${PURPLE}📦 Backend destruction only${NC}"
elif [ "$FRONTEND_ONLY" = true ]; then
    echo -e "${PURPLE}🌐 Frontend destruction only${NC}"
else
    echo -e "${PURPLE}📦🌐 Full destruction (Backend + Frontend + ECR)${NC}"
fi

# Check if terraform.tfvars exists
if [ ! -f "$BACKEND_DIR/terraform.tfvars" ]; then
    print_error "terraform.tfvars not found in tf-backend. Cannot determine configuration."
    exit 1
fi

# Get configuration from terraform.tfvars
AWS_REGION=$(grep 'aws_region' "$BACKEND_DIR/terraform.tfvars" | cut -d'"' -f2)
APP_NAME=$(grep 'app_name' "$BACKEND_DIR/terraform.tfvars" | cut -d'"' -f2)
ENVIRONMENT=$(grep 'environment' "$BACKEND_DIR/terraform.tfvars" | cut -d'"' -f2)
ECR_REPO_NAME="${APP_NAME}-${ENVIRONMENT}"

print_section "Configuration"
echo "  Region: $AWS_REGION"
echo "  App Name: $APP_NAME"
echo "  Environment: $ENVIRONMENT"
echo "  ECR Repository: $ECR_REPO_NAME"

# Check if terraform state exists
if [ ! -f "$BACKEND_DIR/terraform.tfstate" ] && [ ! -f "$FRONTEND_DIR/terraform.tfstate" ]; then
    print_warning "Terraform state files not found. Nothing to destroy."
    exit 0
fi

# Main confirmation prompt
if [ "$FORCE" = false ] && [ "$SKIP_CONFIRM" = false ]; then
    echo ""
    print_danger "⚠️  DESTRUCTION CONFIRMATION ⚠️"
    echo -e "${RED}This will PERMANENTLY DESTROY your infrastructure!${NC}"
    echo -e "${RED}This action CANNOT be undone!${NC}"
    echo ""
    
    if [ "$BACKEND_ONLY" = true ]; then
        echo -e "${YELLOW}The following will be destroyed:${NC}"
        echo "  • Lambda function"
        echo "  • API Gateway"
        echo "  • DynamoDB tables"
        echo "  • IAM roles and policies"
        echo "  • ECR repository (with all images)"
    elif [ "$FRONTEND_ONLY" = true ]; then
        echo -e "${YELLOW}The following will be destroyed:${NC}"
        echo "  • S3 bucket (with all files)"
        echo "  • CloudFront distribution"
        echo "  • IAM roles for deployment"
    else
        echo -e "${YELLOW}The following will be destroyed:${NC}"
        echo "  • Lambda function"
        echo "  • API Gateway"
        echo "  • DynamoDB tables"
        echo "  • S3 bucket (with all files)"
        echo "  • CloudFront distribution"
        echo "  • IAM roles and policies"
        echo "  • ECR repository (with all images)"
    fi
    
    echo ""
    echo -e "${CYAN}Type 'DESTROY' (exactly as shown) to confirm:${NC}"
    
    if [[ -t 0 ]]; then
        read -r confirmation
        if [ "$confirmation" != "DESTROY" ]; then
            print_warning "Destruction cancelled by user."
            exit 0
        fi
    else
        print_warning "Non-interactive mode detected. Proceeding automatically..."
    fi
fi

# Function to cleanup API Gateway resources not in Terraform state
cleanup_api_gateway_not_in_state() {
    print_section "Checking for API Gateway Resources Not in State"
    
    local api_name="${APP_NAME}-${ENVIRONMENT}-api"
    
    # Check if API Gateway exists
    print_status "Looking for API Gateway: $api_name"
    local api_id=$(aws apigateway get-rest-apis --region "$AWS_REGION" --query "items[?name=='$api_name'].id" --output text 2>/dev/null || echo "")
    
    if [ -z "$api_id" ]; then
        print_status "No API Gateway found in AWS."
        return 0
    fi
    
    print_warning "Found API Gateway in AWS: $api_id"
    
    # Check if it's in Terraform state
    cd "$BACKEND_DIR"
    local in_state=$(terraform state list 2>/dev/null | grep "aws_api_gateway_rest_api.main" || echo "")
    
    if [ -z "$in_state" ]; then
        print_warning "API Gateway exists in AWS but NOT in Terraform state!"
        echo ""
        echo -e "${YELLOW}This orphaned API Gateway will be manually deleted.${NC}"
        
        if [ "$SKIP_CONFIRM" = false ] && [ "$FORCE" = false ]; then
            echo -e "${CYAN}Delete orphaned API Gateway? (y/N): ${NC}"
            
            if [[ -t 0 ]]; then
                read -r CONFIRM
                if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                    print_warning "Skipping orphaned API Gateway deletion"
                    return 0
                fi
            fi
        fi
        
        # Delete stages first
        print_status "Deleting all stages..."
        for stage in $(aws apigateway get-stages --rest-api-id "$api_id" --region "$AWS_REGION" --query 'item[].stageName' --output text 2>/dev/null); do
            print_status "Deleting stage: $stage"
            aws apigateway delete-stage --rest-api-id "$api_id" --stage-name "$stage" --region "$AWS_REGION" 2>/dev/null || true
        done
        
        # Delete the API Gateway
        print_status "Deleting orphaned API Gateway..."
        aws apigateway delete-rest-api --rest-api-id "$api_id" --region "$AWS_REGION" && \
            print_success "Orphaned API Gateway deleted" || \
            print_warning "Could not delete orphaned API Gateway"
    else
        print_status "API Gateway is in Terraform state, will be destroyed normally"
    fi
}

# Backend destruction function
destroy_backend() {
    print_section "Backend Destruction"
    
    cd "$BACKEND_DIR"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Clean up any orphaned API Gateway resources before Terraform destroy
    cleanup_api_gateway_not_in_state
    
    # Plan destruction
    print_status "Planning destruction..."
    terraform plan -destroy -out=tfplan-destroy
    
    # Review plan and confirm
    if [ "$SKIP_CONFIRM" = false ] && [ "$FORCE" = false ]; then
        echo -e "\n${YELLOW}📋 Please review the Terraform destruction plan above.${NC}"
        echo -e "${YELLOW}Do you want to proceed with destroying these resources? (y/N):${NC}"
        
        if [[ -t 0 ]]; then
            read -r CONFIRM
            if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                print_error "Destruction cancelled by user."
                print_warning "Cleaning up plan file..."
                rm -f tfplan-destroy
                exit 0
            fi
        else
            print_warning "Non-interactive mode detected. Proceeding automatically..."
        fi
    fi
    
    # Apply destruction
    print_status "Destroying backend infrastructure..."
    terraform apply -auto-approve tfplan-destroy
    
    print_success "Backend destruction complete!"
    
    # Clean up
    rm -f tfplan-destroy
}

# Frontend destruction function
destroy_frontend() {
    print_section "Frontend Destruction"
    
    cd "$FRONTEND_DIR"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Check if frontend resources exist in state
    if ! terraform state list 2>/dev/null | grep -q "aws_s3_bucket.frontend\|aws_cloudfront_distribution.frontend"; then
        print_warning "No frontend resources found in Terraform state."
        return 0
    fi
    
    # Get S3 bucket name before destruction
    S3_BUCKET=$(terraform output -raw frontend_s3_bucket 2>/dev/null || echo "")
    
    if [ -n "$S3_BUCKET" ]; then
        print_status "Emptying S3 bucket: $S3_BUCKET"
        
        # Check if bucket exists
        if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
            # Delete all object versions
            print_status "Deleting all object versions..."
            aws s3api list-object-versions --bucket "$S3_BUCKET" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | \
            jq -r '.[] | "--key \"\(.Key)\" --version-id \"\(.VersionId)\""' | \
            xargs -I {} bash -c "aws s3api delete-object --bucket \"$S3_BUCKET\" {} 2>/dev/null" || print_warning "No versions to delete"
            
            # Delete all delete markers
            print_status "Deleting all delete markers..."
            aws s3api list-object-versions --bucket "$S3_BUCKET" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json | \
            jq -r '.[] | "--key \"\(.Key)\" --version-id \"\(.VersionId)\""' | \
            xargs -I {} bash -c "aws s3api delete-object --bucket \"$S3_BUCKET\" {} 2>/dev/null" || print_warning "No delete markers to delete"
            
            # Final cleanup - delete any remaining current objects
            print_status "Cleaning up any remaining objects..."
            aws s3 rm "s3://$S3_BUCKET" --recursive 2>/dev/null || print_warning "No current objects to delete"
            
            print_success "S3 bucket emptied successfully"
        else
            print_warning "S3 bucket does not exist or cannot be accessed"
        fi
    fi
    
    # Plan destruction for frontend resources only
    print_status "Planning frontend destruction..."
    terraform plan -destroy -target=aws_cloudfront_distribution.frontend -target=aws_s3_bucket.frontend -target=aws_s3_bucket_policy.frontend -target=aws_iam_role.deployment_role -target=aws_iam_policy.deployment_policy -target=aws_iam_role_policy_attachment.deployment -out=tfplan-frontend-destroy
    
    # Apply destruction
    print_status "Destroying frontend infrastructure..."
    terraform apply -auto-approve tfplan-frontend-destroy
    
    print_success "Frontend destruction complete!"
    
    # Clean up
    rm -f tfplan-frontend-destroy
}

# Main destruction logic
main() {
    check_dependencies
    
    # Delete ECR repository if destroying backend or all
    if [ "$FRONTEND_ONLY" = false ] && [ "$SKIP_ECR" = false ]; then
        delete_ecr_repository "$ECR_REPO_NAME" "$AWS_REGION"
    fi
    
    if [ "$FRONTEND_ONLY" = true ]; then
        destroy_frontend
    elif [ "$BACKEND_ONLY" = true ]; then
        destroy_backend
    else
        # Full destruction - destroy frontend first, then backend
        destroy_frontend
        destroy_backend
    fi
    
    print_section "Destruction Summary"
    
    if [ "$FRONTEND_ONLY" = false ]; then
        echo -e "${GREEN}✅ Backend destroyed successfully!${NC}"
    fi
    
    if [ "$BACKEND_ONLY" = false ]; then
        echo -e "${GREEN}✅ Frontend destroyed successfully!${NC}"
    fi
    
    if [ "$FRONTEND_ONLY" = false ] && [ "$SKIP_ECR" = false ]; then
        echo -e "${GREEN}✅ ECR repository destroyed successfully!${NC}"
    fi
    
    echo -e "\n${RED}💀 Infrastructure destruction completed!${NC}"
    
    # Keep terminal open for review
    if [ "$SKIP_CONFIRM" = false ] && [[ -t 0 ]]; then
        echo -e "\n${YELLOW}Press any key to continue or Ctrl+C to exit...${NC}"
        read -n 1 -s
        echo -e "${GREEN}Destruction complete. Terminal will remain open.${NC}"
        exec bash
    else
        echo -e "${GREEN}Destruction complete.${NC}"
    fi
}

# Run main function
main "$@"
