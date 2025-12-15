# Backend Development Guide

FastAPI backend application for the Basic Item CRUD App, designed to run on AWS Lambda with DynamoDB. This guide focuses on **local development**, code structure, and development workflows.

> **Note**: For deployment, infrastructure setup, and production configuration, see the [root README](../README.md).

---

## 📁 Code Structure

The backend follows a modular, functional architecture optimized for FastAPI and serverless deployment:

```
backend/
├── main.py                 # FastAPI app entry point & Lambda handler
├── db.py                   # DynamoDB connection & table references
├── dependencies.py         # FastAPI dependencies (auth, etc.)
├── requirements.txt        # Python dependencies
├── Dockerfile             # Lambda container image definition
│
├── core/                   # Core utilities & configuration
│   ├── config.py          # JWT & app configuration
│   ├── errors.py          # Custom exception handlers
│   ├── logging.py         # Logging configuration
│   ├── observability.py   # Request ID tracking
│   └── security.py        # Password hashing & JWT token creation
│
├── crud/                   # Database operations (pure functions)
│   ├── item.py            # Item CRUD operations
│   └── user.py            # User registration & authentication
│
├── routes/                 # API route definitions
│   ├── item.py            # Item endpoints (create, read, update, delete)
│   └── user.py            # Auth endpoints (register, login, profile)
│
├── schemas/                # Pydantic models for validation
│   ├── item.py            # Item schemas (ItemCreate, ItemRead, ItemUpdate)
│   └── user.py            # User schemas (UserRegister, UserLogin, UserRead)
│
├── middleware/             # FastAPI middleware
│   └── logging.py         # Request/response logging middleware
│
└── test/                   # Test suite
    ├── conftest.py        # Pytest fixtures & DynamoDB Local setup
    ├── test_item_routes.py # Item endpoint tests
    └── test_user_routes.py # User authentication tests
```

---

## 🏗️ Architecture Overview

### Design Principles

- **Functional Programming**: Pure functions for CRUD operations, minimal class usage
- **Dependency Injection**: FastAPI's dependency system for authentication and shared resources
- **Separation of Concerns**: Routes handle HTTP, CRUD handles business logic, schemas handle validation
- **Serverless-First**: Designed for AWS Lambda with Mangum adapter for ASGI compatibility

### Request Flow

1. **API Gateway** → Receives HTTP request
2. **Lambda Handler** (`main.handler`) → Mangum converts API Gateway event to ASGI
3. **FastAPI App** → Routes request through middleware (CORS, logging)
4. **Route Handler** → Validates input via Pydantic schemas, calls dependency injection
5. **Dependency** (`get_current_user`) → Validates JWT token, fetches user from DynamoDB
6. **CRUD Function** → Performs DynamoDB operation, returns data
7. **Response** → Serialized via Pydantic, returned through API Gateway

### Key Components

#### `main.py`
- FastAPI application initialization
- Middleware registration (CORS, request/response logging)
- Router registration (`/api/item`, `/api/user`)
- Exception handler registration
- Lambda handler via Mangum adapter

#### `db.py`
- DynamoDB connection management
- Environment-aware: uses DynamoDB Local for testing (`LOCAL_TESTING=1`)
- Table references via environment variables (`USERS_TABLE`, `ITEMS_TABLE`)

#### `dependencies.py`
- `get_current_user()`: JWT token validation and user lookup
- Used as FastAPI dependency for protected routes

#### `core/security.py`
- Password hashing with bcrypt (`hash_password`, `verify_password`)
- JWT token creation (`create_access_token`)

#### `core/errors.py`
- Custom exception handlers for:
  - `HTTPException`: Standard FastAPI HTTP errors
  - `RequestValidationError`: Pydantic validation errors
  - `ClientError`: DynamoDB boto3 errors
  - `Exception`: Unhandled exceptions (with request ID tracking)

---

## 🚀 Local Development Setup

### Prerequisites

- **Python 3.12+**
- **Docker** (for DynamoDB Local testing)
- **AWS CLI** (configured with credentials for local testing)

### 1. Install Dependencies

```bash
cd backend
python3 -m venv env
source env/bin/activate  # On Windows: env\Scripts\activate
pip install -r requirements.txt
```

### 2. Set Environment Variables

For local development, create a `.env` file or export variables:

```bash
export REGION=us-east-1
export USERS_TABLE=users
export ITEMS_TABLE=items
export LOCAL_TESTING=1  # Use DynamoDB Local
```

**Note**: The app will raise an error if `USERS_TABLE` or `ITEMS_TABLE` are not set.

### 3. Start DynamoDB Local (for Testing)

```bash
docker run -d -p 8000:8000 --name dynamodb-local amazon/dynamodb-local
```

### 4. Run the Application Locally

Using uvicorn (for local development):

```bash
# Set environment variables first
export USERS_TABLE=users
export ITEMS_TABLE=items
export REGION=us-east-1

# Run with uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

**Note**: For production, the app runs on Lambda via the Mangum handler (`main.handler`). Local uvicorn is for development only.

### 5. Access API Documentation

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

---

## 🧪 Testing

### Running Tests

The test suite uses **DynamoDB Local** running in Docker. Ensure DynamoDB Local is running:

```bash
docker ps | grep dynamodb-local
# If not running:
docker run -d -p 8000:8000 --name dynamodb-local amazon/dynamodb-local
```

Run tests:

```bash
cd backend
source env/bin/activate
pytest
```

### Test Configuration

Tests are configured in `test/conftest.py`:

- **Automatic Setup**: Creates `users` and `items` tables in DynamoDB Local
- **Test Isolation**: Module-scoped fixtures ensure clean state
- **Environment**: Sets `LOCAL_TESTING=1` automatically

### Test Structure

- **`test_user_routes.py`**: User registration, login, profile access
- **`test_item_routes.py`**: Item CRUD operations with authentication

### Running Specific Tests

```bash
# Run only user tests
pytest test/test_user_routes.py

# Run only item tests
pytest test/test_item_routes.py

# Run with verbose output
pytest -v

# Run with coverage
pytest --cov=. --cov-report=html
```

---

## 📝 Module Details

### Routes (`routes/`)

**Purpose**: Define HTTP endpoints and request/response handling.

- **`routes/item.py`**: Item CRUD endpoints
  - `POST /api/item/create/` - Create item (requires auth)
  - `GET /api/item/read/` - List user's items (requires auth)
  - `PUT /api/item/update/{item_id}` - Update item (requires auth)
  - `DELETE /api/item/delete/{item_id}` - Delete item (requires auth)

- **`routes/user.py`**: Authentication endpoints
  - `POST /api/user/register/` - Register new user
  - `POST /api/user/login/` - Login and get JWT token
  - `GET /api/user/profile/` - Get user profile (requires auth)

**Pattern**: Routes use Pydantic schemas for validation, call CRUD functions, and return serialized responses.

### CRUD Operations (`crud/`)

**Purpose**: Pure functions for database operations. No HTTP concerns.

- **`crud/item.py`**:
  - `create_item()`: Creates item with `owner_id` from authenticated user
  - `get_items()`: Queries items by `owner_id` using GSI
  - `update_item()`: Updates item with ownership validation
  - `delete_item()`: Deletes item with ownership validation

- **`crud/user.py`**:
  - `register_user()`: Creates user with hashed password, returns JWT
  - `user_login()`: Validates credentials, returns JWT

**Pattern**: Functions accept Pydantic models and `UserRead` objects, return dictionaries or Pydantic models.

### Schemas (`schemas/`)

**Purpose**: Pydantic models for request/response validation and serialization.

- **`schemas/item.py`**:
  - `ItemBase`: Base model with `name` and `description`
  - `ItemCreate`: For creating items (no `id` or `owner_id`)
  - `ItemRead`: For responses (includes `id` and `owner_id`)
  - `ItemUpdate`: For updates (optional fields)

- **`schemas/user.py`**:
  - `UserRegister`: Registration input (username, password)
  - `UserLogin`: Login input (username, password)
  - `UserRead`: User data (id, username, no password)
  - `Token`: JWT token response

**Pattern**: Use Pydantic v2 with `ConfigDict` for configuration.

### Core Utilities (`core/`)

- **`config.py`**: JWT secret key, algorithm, token expiration (should use environment variables in production)
- **`security.py`**: Password hashing (bcrypt) and JWT token creation
- **`errors.py`**: Exception handlers with request ID tracking
- **`logging.py`**: Structured logging configuration
- **`observability.py`**: Request ID generation for tracing

### Middleware (`middleware/`)

- **`logging.py`**: `RequestResponseLogger` middleware logs all requests and responses with timing information

---

## 🔧 Development Workflows

### Adding a New Endpoint

1. **Define Schema** (`schemas/`): Create Pydantic models for request/response
2. **Create CRUD Function** (`crud/`): Pure function for database operation
3. **Add Route** (`routes/`): Define endpoint with dependency injection
4. **Register Router** (`main.py`): Include router in FastAPI app
5. **Write Tests** (`test/`): Add test cases

### Modifying Database Operations

- Edit functions in `crud/` directory
- Ensure ownership checks for user-specific resources
- Use DynamoDB query operations with GSI for efficient lookups
- Handle `ClientError` exceptions (caught by `core/errors.py`)

### Debugging

- **Local Logs**: Check uvicorn console output
- **CloudWatch Logs** (production): `aws logs tail /aws/lambda/<function-name> --follow`
- **Request IDs**: All errors include `request_id` for tracing
- **DynamoDB Local**: Query tables directly: `aws dynamodb scan --table-name users --endpoint-url http://localhost:8000`

---

## 🔐 Authentication Flow

1. **Registration**: User provides username/password → Password hashed with bcrypt → User stored in DynamoDB → JWT token returned
2. **Login**: User provides username/password → Password verified → JWT token returned
3. **Protected Routes**: Request includes `Authorization: Bearer <token>` → `get_current_user()` validates token → User fetched from DynamoDB → Route handler receives `UserRead` object

**JWT Token Structure**:
- Payload: `{"sub": user_id, "exp": expiration_timestamp}`
- Algorithm: HS256
- Expiration: 30 minutes (configurable in `core/config.py`)

---

## 🐳 Docker Development

The `Dockerfile` is optimized for AWS Lambda deployment. For local Docker testing:

```bash
# Build image
docker build --platform linux/amd64 --provenance=false -t backend-local .

# Run locally (requires environment variables)
docker run -p 9000:8080 \
  -e USERS_TABLE=users \
  -e ITEMS_TABLE=items \
  -e REGION=us-east-1 \
  backend-local
```

**Note**: Lambda container images use the `public.ecr.aws/lambda/python:3.12` base image, which includes the Lambda Runtime Interface Client.

---

## 📦 Dependencies

Key dependencies (see `requirements.txt` for full list):

- **FastAPI**: Web framework
- **Mangum**: ASGI adapter for Lambda
- **boto3**: AWS SDK for DynamoDB
- **python-jose**: JWT token handling
- **passlib[bcrypt]**: Password hashing
- **pydantic**: Data validation
- **pytest**: Testing framework

---

## 🚨 Common Development Issues

### Issue: `USERS_TABLE and ITEMS_TABLE environment variables must be set`

**Solution**: Export environment variables before running:
```bash
export USERS_TABLE=users
export ITEMS_TABLE=items
```

### Issue: Tests fail with "ResourceNotFoundException"

**Solution**: Ensure DynamoDB Local is running:
```bash
docker ps | grep dynamodb-local
docker start dynamodb-local  # if stopped
```

### Issue: CORS errors in browser

**Solution**: Check `ALLOWED_ORIGINS` in `main.py` includes your frontend URL.

### Issue: JWT token validation fails

**Solution**: Ensure `SECRET_KEY` in `core/config.py` matches between token creation and validation (in production, use AWS Secrets Manager).

---

## 📚 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Mangum Documentation](https://mangum.io/)
- [DynamoDB Local Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html)
- [Pydantic v2 Documentation](https://docs.pydantic.dev/)

---

**For deployment, infrastructure, and production configuration, see the [root README](../README.md).**
