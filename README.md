# Basic Item CRUD App - Serverless Full-Stack Application

A production-ready serverless full-stack application built with FastAPI, DynamoDB, and AWS Lambda, featuring user authentication and item management with a modern static frontend deployed on AWS CloudFront.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Setup Instructions](#-setup-instructions)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Usage](#-usage)
- [Testing](#-testing)
- [Project Structure](#-project-structure)
- [Troubleshooting](#-troubleshooting)
- [Security](#-security)

---

## 🎯 Overview

This application provides a complete serverless solution for managing items with user authentication. The backend is built with FastAPI and deployed on AWS Lambda using Docker containers, while the frontend is a static site served via S3 and CloudFront. All data is persisted in DynamoDB, making this a fully managed, scalable solution.

### Target Audience

- Developers looking to build serverless applications on AWS
- Teams needing a production-ready CRUD application template
- Anyone learning FastAPI, AWS Lambda, and serverless architecture

### Why Use This Application

- **Serverless Architecture**: No servers to manage, automatic scaling, pay-per-use pricing
- **Production Ready**: Includes authentication, error handling, logging, and comprehensive testing
- **Modern Stack**: FastAPI for high-performance APIs, DynamoDB for NoSQL data storage
- **Full-Stack**: Complete frontend and backend with deployment automation

### Workflow

1. **User Registration/Login**: Users register or login to receive a JWT token
2. **Item Management**: Authenticated users can create, read, update, and delete items
3. **Data Persistence**: All operations are stored in DynamoDB with proper indexing
4. **API Access**: RESTful API endpoints accessible via API Gateway
5. **Frontend Interaction**: Static frontend communicates with backend via API calls

---

## 🏗️ Architecture

### Visual Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet Users                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    CloudFront Distribution                   │
│              (Static Frontend - S3 Origin)                   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ API Calls
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway (REST)                      │
│              (HTTP Routing & CORS Handling)                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Proxy Integration
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Lambda Function (Docker Container)             │
│                    FastAPI Application                       │
│              (Mangum Adapter for ASGI)                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ IAM Role
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      DynamoDB Tables                         │
│  ┌──────────────┐              ┌──────────────┐            │
│  │   users      │              │    items     │            │
│  │ (id, username│              │ (id, owner_id│            │
│  │  password)   │              │  name, desc) │            │
│  └──────────────┘              └──────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Frontend Request**: User interacts with static frontend (HTML/JS) served from CloudFront
2. **API Gateway**: Request is routed through API Gateway REST API with CORS configuration
3. **Lambda Execution**: API Gateway invokes Lambda function with Docker container image
4. **FastAPI Processing**: Mangum adapter converts API Gateway event to ASGI request
5. **Authentication**: JWT token validated via dependency injection
6. **DynamoDB Operations**: CRUD operations performed on DynamoDB tables using boto3
7. **Response**: JSON response returned through API Gateway to frontend

### Components

- **CloudFront Distribution**: CDN for static frontend files with S3 origin
- **S3 Bucket**: Storage for static HTML, CSS, and JavaScript files
- **API Gateway REST API**: HTTP endpoint routing with proxy integration to Lambda
- **Lambda Function**: FastAPI application running in Docker container (Python 3.12)
- **ECR Repository**: Container registry for Lambda Docker images
- **DynamoDB Tables**: 
  - `users`: User authentication data with username GSI
  - `items`: Item data with owner_id GSI for user-specific queries
- **IAM Roles**: Least-privilege permissions for Lambda to access DynamoDB
- **CloudWatch Logs**: Centralized logging for Lambda and API Gateway

---

## ✨ Features

- 🔐 **User Authentication**: Secure registration and login with JWT tokens and bcrypt password hashing
- 📦 **Item CRUD Operations**: Full Create, Read, Update, Delete functionality for items
- 🚀 **Serverless Architecture**: Deployed on AWS Lambda with automatic scaling
- 🐳 **Docker Containerization**: Lambda function runs in Docker for consistent deployments
- 📊 **DynamoDB Integration**: NoSQL database with Global Secondary Indexes for efficient queries
- 🌐 **Static Frontend**: Modern HTML/CSS/JavaScript frontend with CloudFront CDN
- 🧪 **Comprehensive Testing**: Pytest test suite with DynamoDB Local for integration testing
- 📝 **Request/Response Logging**: Middleware for logging all API requests and responses
- ⚡ **Error Handling**: Custom exception handlers for validation, client errors, and unhandled exceptions
- 🔒 **CORS Configuration**: Properly configured CORS for frontend-backend communication
- 📈 **CloudWatch Integration**: Automatic logging and monitoring via AWS CloudWatch

---

## 📦 Prerequisites

Before you begin, ensure you have the following:

### Required Tools

- **Python** (3.12 or higher) - [Installation Guide](https://www.python.org/downloads/)
- **AWS CLI** (latest version) - [Installation Guide](https://aws.amazon.com/cli/)
- **Terraform** (>= 1.0) - [Installation Guide](https://www.terraform.io/downloads)
- **Docker** (latest version) - [Installation Guide](https://docs.docker.com/get-docker/)
- **Git** - [Installation Guide](https://git-scm.com/downloads)

### AWS Account Requirements

- An AWS account with appropriate permissions
- AWS credentials configured (via `aws configure` or environment variables)
- Access to the following AWS services:
  - Lambda
  - API Gateway
  - DynamoDB
  - S3
  - CloudFront
  - ECR (Elastic Container Registry)
  - IAM
  - CloudWatch

### Additional Configuration

- **Docker Desktop** (or Docker Engine) must be running for building container images
- **Terraform Backend**: S3 bucket for Terraform state (optional but recommended)

---

## 🚀 Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Basic_Item_CRUD_App
```

### 2. Configure AWS Credentials

Ensure your AWS credentials are configured:

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### 3. Set Up Backend Environment

Navigate to the backend directory and set up a virtual environment:

```bash
cd backend
python3 -m venv env
source env/bin/activate  # On Windows: env\Scripts\activate
pip install -r requirements.txt
```

**Note**: The backend uses environment variables for configuration. For local development, you may need to set up DynamoDB Local (see Testing section).

### 4. Configure Terraform Variables

Set up Terraform configuration for infrastructure deployment:

```bash
cd infra/terraform/tf-backend
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

Key variables to configure:
- `app_name`: Name for your application (e.g., "basic-item-crud")
- `environment`: Environment name (e.g., "dev", "prod")
- `aws_region`: AWS region (default: "us-east-1")

### 5. Configure Frontend API Endpoint

Before deploying the frontend, update the API endpoint in the frontend JavaScript:

```bash
cd frontend/js
# Edit app.js and update API_BASE with your API Gateway URL
```

The API URL will be available after backend deployment.

### 6. Verify Setup

Test that all tools are installed correctly:

```bash
# Check Python
python3 --version

# Check AWS CLI
aws --version

# Check Terraform
terraform version

# Check Docker
docker --version
```

---

## ⚙️ Configuration

### Backend Configuration

The backend uses environment variables configured in the Lambda function. Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `REGION` | AWS region for DynamoDB | `us-east-1` |
| `USERS_TABLE` | DynamoDB users table name | `{app_name}-{env}-users` |
| `ITEMS_TABLE` | DynamoDB items table name | `{app_name}-{env}-items` |
| `SECRET_KEY` | JWT secret key | Set in `core/config.py` |
| `ALGORITHM` | JWT algorithm | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiration time | `30` |

### Terraform Variables

Key variables in `terraform.tfvars`:

| Variable | Description | Example |
|----------|-------------|---------|
| `app_name` | Application name prefix | `basic-item-crud` |
| `environment` | Environment name | `dev` |
| `aws_region` | AWS region | `us-east-1` |
| `lambda_memory_size` | Lambda memory allocation | `512` |
| `lambda_timeout` | Lambda timeout in seconds | `30` |

### Frontend Configuration

The frontend JavaScript configuration in `frontend/js/app.js`:

- `API_BASE`: Base URL for API Gateway endpoint (set after deployment)
- Endpoint paths: `/api/user/register/`, `/api/user/login/`, `/api/item/*`

### CORS Configuration

CORS is configured in `backend/main.py` with allowed origins:
- CloudFront domain (production)
- `http://localhost:5500` (local development)

---

## 🚢 Deployment

### Initial Deployment

Deploy both backend and frontend using the automated script:

```bash
cd infra/scripts
./deploy-all.sh
```

This script will:
1. Check for required dependencies (AWS CLI, Terraform, Docker)
2. Deploy backend infrastructure (Lambda, API Gateway, DynamoDB, ECR)
3. Build and push Docker image to ECR
4. Deploy frontend infrastructure (S3, CloudFront)
5. Upload frontend files to S3
6. Invalidate CloudFront cache

### Backend-Only Deployment

To deploy only the backend:

```bash
cd infra/scripts
./deploy-all.sh --backend-only
```

### Frontend-Only Deployment

To update only the frontend (requires backend to exist):

```bash
cd infra/scripts
./deploy-all.sh --frontend-only
```

### Deployment Options

The deployment script supports several options:

```bash
# Skip confirmation prompts
./deploy-all.sh --skip-confirm

# Skip Docker build/push (use existing image)
./deploy-all.sh --skip-docker

# Combine options
./deploy-all.sh --backend-only --skip-confirm
```

### Manual Deployment (Alternative)

If you prefer to use Terraform directly:

#### Backend Deployment

```bash
cd infra/terraform/tf-backend

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply infrastructure
terraform apply

# Get ECR repository URL
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO_URL

# Build and push Docker image
docker build --platform linux/amd64 --provenance=false -t basic-item-crud ../../backend/
docker tag basic-item-crud:latest $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:latest

# Update Lambda function
aws lambda update-function-code \
  --function-name $(terraform output -raw lambda_function_name) \
  --image-uri $ECR_REPO_URL:latest
```

#### Frontend Deployment

```bash
cd infra/terraform/tf-frontend

# Initialize Terraform
terraform init

# Apply infrastructure
terraform apply

# Get S3 bucket name
S3_BUCKET=$(terraform output -raw frontend_s3_bucket)

# Upload files
aws s3 sync ../../frontend s3://$S3_BUCKET --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw frontend_cloudfront_distribution_id) \
  --paths "/*"
```

### Update Deployment

To update the application with new code:

```bash
# Full update (rebuilds Docker image and redeploys)
./deploy-all.sh

# Update only code (skip Docker rebuild)
./deploy-all.sh --skip-docker
```

---

## 📖 Usage

### API Endpoints

After deployment, your API will be available at:
```
https://<api-gateway-id>.execute-api.us-east-1.amazonaws.com/<stage>/
```

#### Authentication Endpoints

**Register User**:
```bash
POST /api/user/register/
Content-Type: application/json

{
  "username": "john_doe",
  "password": "secure_password123"
}
```

**Login**:
```bash
POST /api/user/login/
Content-Type: application/json

{
  "username": "john_doe",
  "password": "secure_password123"
}

Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Get Profile** (requires authentication):
```bash
GET /api/user/profile/
Authorization: Bearer <access_token>
```

#### Item Endpoints

All item endpoints require authentication via Bearer token:

**Create Item**:
```bash
POST /api/item/create/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "My Item",
  "description": "Item description"
}
```

**List Items**:
```bash
GET /api/item/read/
Authorization: Bearer <access_token>
```

**Update Item**:
```bash
PUT /api/item/update/{item_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Updated Item Name",
  "description": "Updated description"
}
```

**Delete Item**:
```bash
DELETE /api/item/delete/{item_id}
Authorization: Bearer <access_token>
```

**Health Check**:
```bash
GET /api/health
```

### Using the Frontend

1. **Access the Application**: Navigate to your CloudFront URL (provided after deployment)
2. **Register**: Create a new account via the registration page
3. **Login**: Use your credentials to log in
4. **Manage Items**: Once logged in, you can create, view, update, and delete items

### Viewing Results

**CloudWatch Logs**: View Lambda execution logs:

```bash
# Lambda function logs
aws logs tail /aws/lambda/<function-name> --follow --region us-east-1

# API Gateway logs
aws logs tail /aws/apigateway/<api-name> --follow --region us-east-1
```

**DynamoDB Tables**: Query tables directly:

```bash
# List all users
aws dynamodb scan --table-name <users-table-name> --region us-east-1

# List all items
aws dynamodb scan --table-name <items-table-name> --region us-east-1
```

**API Gateway Metrics**: Check API performance:

```bash
# Get API Gateway details
aws apigateway get-rest-api --rest-api-id <api-id> --region us-east-1
```

### Manual Testing

You can test the API using curl:

```bash
# Set your API Gateway URL
API_URL="https://<api-id>.execute-api.us-east-1.amazonaws.com/<stage>"

# Register a user
curl -X POST "$API_URL/api/user/register/" \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpass123"}'

# Login
TOKEN=$(curl -X POST "$API_URL/api/user/login/" \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpass123"}' \
  | jq -r '.access_token')

# Create an item
curl -X POST "$API_URL/api/item/create/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Item", "description": "Test Description"}'
```

**Important Note**: Ensure your JWT token is included in the `Authorization` header for all protected endpoints. Tokens expire after 30 minutes by default.

---

## 🧪 Testing

### Prerequisites for Testing

The test suite uses **DynamoDB Local** for integration testing. You need to run DynamoDB Local in a Docker container:

```bash
docker run -d -p 8000:8000 --name dynamodb-local amazon/dynamodb-local
```

**Note**: The test suite will automatically create the required tables in DynamoDB Local when tests run.

### Running Tests

Navigate to the backend directory and run the test suite:

```bash
cd backend
source env/bin/activate  # Activate virtual environment if not already active
pytest
```

### Test Coverage

The test suite includes:

#### User Authentication Tests (`test/test_user_routes.py`)
- ✅ **User Registration**: Tests user registration endpoint
- ✅ **User Login**: Tests login endpoint and token generation
- ✅ **User Profile**: Tests authenticated profile access

#### Item CRUD Tests (`test/test_item_routes.py`)
- ✅ **Create Item**: Tests item creation with authentication
- ✅ **Read Items**: Tests listing all items for authenticated user
- ✅ **Update Item**: Tests item update functionality
- ✅ **Delete Item**: Tests item deletion

### Running Specific Tests

```bash
# Run only user tests
pytest test/test_user_routes.py

# Run only item tests
pytest test/test_item_routes.py

# Run with verbose output
pytest -v

# Run with coverage report
pytest --cov=. --cov-report=html
```

### Test Configuration

Tests are configured in `test/conftest.py`:
- **DynamoDB Local**: Connects to `http://localhost:8000`
- **Table Creation**: Automatically creates `users` and `items` tables
- **Test Isolation**: Each test module uses module-scoped fixtures
- **Environment Variable**: `LOCAL_TESTING=1` is set for test runs

### Test Fixtures

The test suite provides several fixtures:

- `test_client`: FastAPI TestClient instance
- `auth_token`: JWT token for authenticated requests (created via registration/login)
- `created_item_id`: ID of an item created during test setup

### Example Test Output

```
test/test_user_routes.py::test_create_user PASSED
test/test_user_routes.py::test_login_and_get_profile PASSED
test/test_item_routes.py::test_create_item PASSED
test/test_item_routes.py::test_update_item PASSED
test/test_item_routes.py::test_read_item PASSED
test/test_item_routes.py::test_delete_item PASSED

======================== 6 passed in 2.34s ========================
```

### Troubleshooting Tests

**Issue**: Tests fail with "ResourceNotFoundException"
- **Solution**: Ensure DynamoDB Local is running: `docker ps | grep dynamodb-local`
- **Solution**: Restart DynamoDB Local: `docker restart dynamodb-local`

**Issue**: Tests fail with connection errors
- **Solution**: Check that DynamoDB Local is accessible on port 8000: `curl http://localhost:8000`
- **Solution**: Verify Docker container is running: `docker ps`

**Issue**: Tests create duplicate users
- **Solution**: This is expected behavior - tests check for existing users and handle gracefully
- **Solution**: Clean up DynamoDB Local tables if needed: `docker restart dynamodb-local`

---

## 📁 Project Structure

```
Basic_Item_CRUD_App/
├── backend/                    # FastAPI backend application
│   ├── core/                   # Core configuration and utilities
│   │   ├── config.py          # Application configuration
│   │   ├── errors.py          # Custom exception handlers
│   │   ├── logging.py         # Logging configuration
│   │   ├── observability.py   # Observability utilities
│   │   └── security.py        # Security utilities (JWT, password hashing)
│   ├── crud/                   # Database CRUD operations
│   │   ├── item.py            # Item CRUD functions
│   │   └── user.py            # User CRUD functions
│   ├── middleware/             # FastAPI middleware
│   │   └── logging.py         # Request/response logging middleware
│   ├── routes/                 # API route definitions
│   │   ├── item.py            # Item endpoints
│   │   └── user.py            # User authentication endpoints
│   ├── schemas/                # Pydantic models
│   │   ├── item.py            # Item schemas (create, read, update)
│   │   └── user.py            # User schemas (register, login, read)
│   ├── test/                   # Test suite
│   │   ├── conftest.py        # Pytest configuration and fixtures
│   │   ├── test_item_routes.py # Item endpoint tests
│   │   └── test_user_routes.py # User endpoint tests
│   ├── db.py                   # DynamoDB connection and utilities
│   ├── dependencies.py        # FastAPI dependencies (auth, etc.)
│   ├── main.py                # FastAPI application entry point
│   ├── Dockerfile             # Docker image for Lambda
│   ├── requirements.txt       # Python dependencies
│   └── README.md              # Backend-specific documentation
├── frontend/                   # Static frontend application
│   ├── css/
│   │   └── style.css          # Application styles
│   ├── js/
│   │   ├── app.js             # Main application logic
│   │   ├── items.js           # Item management logic
│   │   ├── login.js           # Login functionality
│   │   └── register.js        # Registration functionality
│   ├── index.html             # Landing page
│   ├── login.html             # Login page
│   ├── register.html          # Registration page
│   ├── items.html             # Item management page
│   ├── thankyou.html          # Post-registration page
│   └── README.md              # Frontend-specific documentation
├── infra/                      # Infrastructure as Code
│   ├── scripts/
│   │   ├── deploy-all.sh      # Automated deployment script
│   │   └── destroy-all.sh    # Infrastructure teardown script
│   ├── terraform/
│   │   ├── tf-backend/        # Backend infrastructure (Lambda, API Gateway, DynamoDB)
│   │   │   ├── api_gateway.tf # API Gateway configuration
│   │   │   ├── dynamodb.tf    # DynamoDB tables
│   │   │   ├── iam.tf         # IAM roles and policies
│   │   │   ├── lambda.tf     # Lambda function configuration
│   │   │   ├── main.tf       # Main Terraform configuration
│   │   │   ├── outputs.tf    # Terraform outputs
│   │   │   └── variables.tf   # Variable definitions
│   │   └── tf-frontend/       # Frontend infrastructure (S3, CloudFront)
│   │       ├── cloudfront.tf  # CloudFront distribution
│   │       ├── iam.tf         # IAM roles for S3 access
│   │       ├── main.tf       # Main Terraform configuration
│   │       ├── outputs.tf    # Terraform outputs
│   │       ├── s3.tf         # S3 bucket configuration
│   │       └── variables.tf  # Variable definitions
│   ├── DEPLOYMENT_GUIDE.md    # Detailed deployment instructions
│   ├── FRONTEND_DEPLOYMENT.md # Frontend deployment guide
│   └── README.md              # Infrastructure documentation
└── README.md                  # This file
```

---

## 🔧 Troubleshooting

### Deployment Issues

**Issue**: Terraform fails with "API Gateway already exists"
- **Solution**: The deployment script handles this automatically. If manual intervention is needed:
  ```bash
  # Import existing API Gateway
  terraform import aws_api_gateway_rest_api.main <api-id>
  
  # Or delete and recreate
  aws apigateway delete-rest-api --rest-api-id <api-id>
  ```

**Issue**: Docker build fails with platform error
- **Solution**: Ensure you're building for Linux/AMD64:
  ```bash
  docker build --platform linux/amd64 --provenance=false -t basic-item-crud ./backend
  ```

**Issue**: Lambda timeout errors
- **Solution**: Increase Lambda timeout in `terraform.tfvars`:
  ```hcl
  lambda_timeout = 60  # Increase from default 30
  ```

### Runtime Issues

**Issue**: CORS errors in browser console
- **Solution**: Verify CloudFront domain is in `ALLOWED_ORIGINS` in `backend/main.py`
- **Solution**: Check API Gateway CORS configuration matches frontend domain

**Issue**: "Unauthorized" errors on protected endpoints
- **Solution**: Verify JWT token is included in `Authorization: Bearer <token>` header
- **Solution**: Check token hasn't expired (default: 30 minutes)
- **Solution**: Verify token was obtained from `/api/user/login/` endpoint

**Issue**: DynamoDB access denied errors
- **Solution**: Check Lambda IAM role has DynamoDB permissions
- **Solution**: Verify table names match environment variables
- **Solution**: Check IAM policy allows `dynamodb:PutItem`, `dynamodb:GetItem`, etc.

### Common Fixes

**Reset DynamoDB Local** (for testing):
```bash
docker restart dynamodb-local
```

**View Lambda Logs**:
```bash
aws logs tail /aws/lambda/<function-name> --follow --region us-east-1
```

**Check API Gateway Status**:
```bash
aws apigateway get-rest-api --rest-api-id <api-id> --region us-east-1
```

**Invalidate CloudFront Cache**:
```bash
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"
```

**Clean Up Resources**:
```bash
cd infra/scripts
./destroy-all.sh
```

---

## 🔒 Security

### Best Practices

- **JWT Token Security**: Tokens are signed with a secret key and expire after 30 minutes. In production, use a strong, randomly generated `SECRET_KEY` stored in AWS Secrets Manager or Parameter Store.

- **Password Hashing**: All passwords are hashed using bcrypt before storage in DynamoDB. Never store plain-text passwords.

- **Least Privilege IAM**: Lambda function IAM role has minimal permissions - only the specific DynamoDB operations needed (GetItem, PutItem, UpdateItem, DeleteItem, Query).

- **CORS Configuration**: CORS is restricted to specific allowed origins (CloudFront domain and localhost for development). This prevents unauthorized domains from accessing the API.

- **Input Validation**: All API inputs are validated using Pydantic models, preventing injection attacks and malformed data.

- **Error Handling**: Custom exception handlers prevent sensitive information from being exposed in error responses.

- **DynamoDB Encryption**: DynamoDB tables have encryption at rest enabled by default.

- **API Gateway Security**: Consider adding API keys, rate limiting, or AWS WAF for additional protection in production.

- **Environment Variables**: Sensitive configuration (like JWT secret) should be stored in AWS Secrets Manager rather than hardcoded.

- **Container Security**: Docker images are built with minimal dependencies and scanned for vulnerabilities before deployment.

---

## 📄 License

This project is provided as-is for educational and development purposes. Feel free to use, modify, and distribute according to your needs.

---

## 🤝 Contributing

Contributions are welcome! Please ensure:
- All tests pass (`pytest`)
- Code follows the project's style guidelines
- New features include appropriate tests
- Documentation is updated

---

## 📚 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Mangum Documentation](https://mangum.io/)

---

**Note**: This README follows the project's README framework standards. For project-specific questions, refer to the individual component READMEs in `backend/README.md`, `frontend/README.md`, and `infra/README.md`.

