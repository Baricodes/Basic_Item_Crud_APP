# main.py
from fastapi import FastAPI, HTTPException
from mangum import Mangum

from core.logging import configure_logging
from core.errors import (
    http_exception_handler,
    validation_exception_handler,
    client_error_handler,
    unhandled_exception_handler,
)
from middleware.logging import RequestResponseLogger
from routes.item import item_router
from routes.user import user_router

# 4) Exception handlers
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from botocore.exceptions import ClientError

ALLOWED_ORIGINS = [
    #My CloudFront Website Domain,
    "http://localhost:5500"
]

# 1) Logging first
configure_logging()

app = FastAPI(title="FastAPI + DynamoDB on Lambda")

# CORS (attach CORS kwargs to CORSMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,   # using Bearer tokens, not cookies
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

# Your request/response logger (no CORS kwargs)
app.add_middleware(RequestResponseLogger)

# Register routers
app.include_router(item_router, prefix="/item")
app.include_router(user_router, prefix="/user")

app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(ClientError, client_error_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

# Healthcheck (handy for logs)
@app.get("/health")
def health():
    return {"status": "ok"}

# Lambda handler
handler = Mangum(app, lifespan="off")
