from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
import time
from contextvars import ContextVar
import structlog
import uuid

request_id_var = ContextVar("request_id", default="")
user_id_var = ContextVar("user_id", default="")
patient_id_var = ContextVar("patient_id", default="")

logger = structlog.get_logger()

class LogMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        req_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request_id_var.set(req_id)
        
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(request_id=req_id)
        
        response = await call_next(request)
        
        latency_ms = (time.time() - start_time) * 1000
        logger.info("api_request", method=request.method, path=request.url.path, status=response.status_code, latency_ms=latency_ms)
        return response
