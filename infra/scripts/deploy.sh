#!/bin/bash

# Deploy script for Basic Item CRUD App on AWS
set -Eeuo pipefail

# Helpful error message
trap 'echo -e "\n[ERROR] Failed at line $LINENO: $BASH_COMMAND"; if [[ -t 0 ]]; then echo -e "\n${YELLOW}Press any key to close this terminal...${NC}"; read -n 1 -s; fi; exit 1' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment of Basic Item CRUD App${NC}"

# Check if terraform.tfvars exists
if [ ! -f "../terraform/terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  terraform.tfvars not found. Creating from example...${NC}"
    cp ../terraform/terraform.tfvars.example ../terraform/terraform.tfvars
    echo -e "${YELLOW}📝 Please edit terraform.tfvars with your values before continuing${NC}"
    exit 1
fi

# Get AWS region from terraform.tfvars
AWS_REGION=$(grep 'aws_region' ../terraform/terraform.tfvars | cut -d'"' -f2)
APP_NAME=$(grep 'app_name' ../terraform/terraform.tfvars | cut -d'"' -f2)
ENVIRONMENT=$(grep 'environment' ../terraform/terraform.tfvars | cut -d'"' -f2)

echo -e "${GREEN}📋 Configuration:${NC}"
echo "  Region: $AWS_REGION"
echo "  App Name: $APP_NAME"
echo "  Environment: $ENVIRONMENT"

# Initialize Terraform
echo -e "${GREEN}🔧 Initializing Terraform...${NC}"
cd ../terraform
terraform init

# Plan deployment
echo -e "${GREEN}📋 Planning deployment...${NC}"
terraform plan -out=tfplan

# Review plan and confirm
echo -e "\n${YELLOW}📋 Please review the Terraform plan above.${NC}"
echo -e "${YELLOW}Do you want to proceed with applying these changes? (y/N):${NC}"

# Check if we're in an interactive terminal
if [[ -t 0 ]]; then
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Deployment cancelled by user.${NC}"
        echo -e "${YELLOW}Cleaning up plan file...${NC}"
        rm -f tfplan
        echo -e "${YELLOW}Press any key to close this terminal...${NC}"
        read -n 1 -s
        exit 0
    fi
else
    echo -e "${YELLOW}⚠️  Non-interactive mode detected. Proceeding automatically...${NC}"
    echo -e "${GREEN}✅ Auto-confirming deployment (use -i flag or run interactively to get prompts)${NC}"
fi

# First, create ECR repository so we can push Docker image
echo -e "${GREEN}🚀 Creating ECR repository...${NC}"
terraform apply -target=aws_ecr_repository.main -target=aws_ecr_lifecycle_policy.main -auto-approve

# Get ECR repository URL
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)

echo -e "${GREEN}📦 Building and pushing Docker image...${NC}"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL

# Build Docker image
echo "Building Docker image..."
docker build --platform linux/amd64 --provenance=false -t $APP_NAME ../../backend/

# Tag image
echo "Tagging image..."
docker tag $APP_NAME:latest $ECR_REPO_URL:latest

# Push image
echo "Pushing image to ECR..."
docker push $ECR_REPO_URL:latest

# Now apply the full infrastructure
echo -e "${GREEN}🚀 Applying full deployment...${NC}"
terraform apply -auto-approve

# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_invoke_url)

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${GREEN}🌐 API URL: $API_URL${NC}"
echo -e "${GREEN}🔍 Test health endpoint: $API_URL/health${NC}"

# Clean up
rm -f tfplan

echo -e "${GREEN}🎉 Deployment finished successfully!${NC}"

# Keep terminal open for review
echo -e "${YELLOW}Press any key to continue or Ctrl+C to exit...${NC}"
if [[ -t 0 ]]; then
    read -n 1 -s
    echo -e "${GREEN}Deployment complete. Terminal will remain open.${NC}"
    exec bash
else
    echo -e "${GREEN}Deployment complete. Non-interactive mode - script finished.${NC}"
fi
