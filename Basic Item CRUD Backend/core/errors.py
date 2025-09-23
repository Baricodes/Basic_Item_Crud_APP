# core/errors.py
import logging, os
from fastapi import Request
from fastapi.responses import JSONResponse
from botocore.exceptions import ClientError
from core.observability import get_request_id

logger = logging.getLogger("app.errors")

DEBUG = "true"

async def http_exception_handler(request: Request, exc):
    # FastAPI's HTTPException
    payload = {
        "detail": exc.detail,
        "request_id": get_request_id(),
    }
    logger.warning("HTTPException", extra={
        "request_id": payload["request_id"],
        "path": request.url.path,
        "status_code": exc.status_code,
    })
    return JSONResponse(payload, status_code=exc.status_code)

async def validation_exception_handler(request: Request, exc):
    payload = {
        "detail": exc.errors(),
        "request_id": get_request_id(),
    }
    logger.warning("ValidationError", extra={
        "request_id": payload["request_id"],
        "path": request.url.path,
        "status_code": 422,
    })
    return JSONResponse(payload, status_code=422)

async def client_error_handler(request: Request, exc: ClientError):
    rid = get_request_id()
    code = exc.response.get("Error", {}).get("Code")
    msg  = exc.response.get("Error", {}).get("Message")
    logger.error("DynamoDB ClientError", extra={
        "request_id": rid,
        "path": request.url.path,
        "status_code": 500,
        "dynamodb_code": code,
        "dynamodb_message": msg,
    }, exc_info=True)
    return JSONResponse(
        {"detail": "DynamoDB error", "aws_error_code": code, "request_id": rid},
        status_code=500,
    )

async def unhandled_exception_handler(request: Request, exc: Exception):
    rid = get_request_id()
    logger.error("Unhandled exception", extra={
        "request_id": rid,
        "path": request.url.path,
        "status_code": 500,
    }, exc_info=True)
    if DEBUG:
        # Show full message and type in dev
        return JSONResponse({"detail": str(exc), "type": exc.__class__.__name__, "request_id": rid}, status_code=500)
    return JSONResponse({"detail": "Internal Server Error", "request_id": rid}, status_code=500)
