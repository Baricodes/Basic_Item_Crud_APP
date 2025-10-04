# middleware/logging.py
import json, logging, time
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import Message
from core.observability import new_request_id, get_request_id

logger = logging.getLogger("app.request")

MAX_BODY_LOG_BYTES = 2048  # cap body logging

SENSITIVE_HEADERS = {"authorization", "cookie", "set-cookie"}

def _redact_headers(headers: dict) -> dict:
    redacted = {}
    for k, v in headers.items():
        if k.lower() in SENSITIVE_HEADERS:
            redacted[k] = "***REDACTED***"
        else:
            redacted[k] = v
    return redacted

class RequestResponseLogger(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Correlation ID
        request_id = request.headers.get("x-request-id") or new_request_id()

        start = time.time()
        # Read/copy body safely
        body = await request.body()
        body_preview = body[:MAX_BODY_LOG_BYTES].decode("utf-8", errors="replace")

        # Log incoming request
        logger.info(
            "HTTP request",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
            },
        )

        # Re-inject body so downstream can read it
        async def receive() -> Message:
            return {"type": "http.request", "body": body, "more_body": False}

        # Execute endpoint
        response: Response = await call_next(Request(request.scope, receive))

        # Capture response (status + limited text bodies)
        duration_ms = int((time.time() - start) * 1000)

        headers_dict = _redact_headers(dict(request.headers))
        log_data = {
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
            "request_headers": headers_dict,
        }

        # Only log request/response bodies for JSON or form routes (and not huge)
        content_type = (request.headers.get("content-type") or "").lower()
        if "application/json" in content_type or "application/x-www-form-urlencoded" in content_type:
            log_data["request_body"] = body_preview

        # Try to peek small JSON responses
        try:
            if response.media_type == "application/json" and hasattr(response, "body_iterator"):
                # Starlette JSONResponse exposes body via body_iterator; we’ll skip to avoid consuming it.
                pass
        except Exception:
            pass

        logger.info("HTTP response", extra=log_data)

        # Propagate request ID to client
        response.headers["X-Request-ID"] = request_id
        return response
