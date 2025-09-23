# core/observability.py
import uuid
from contextvars import ContextVar

request_id_ctx: ContextVar[str] = ContextVar("request_id", default="")

def new_request_id() -> str:
    rid = uuid.uuid4().hex
    request_id_ctx.set(rid)
    return rid

def get_request_id() -> str:
    rid = request_id_ctx.get()
    return rid or new_request_id()
