from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
import redis.asyncio as redis
from datetime import datetime
from app.config import settings

redis_client = redis.from_url(settings.redis_url, decode_responses=True)

class AuditMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host
        
        # Rule 3: Failed Login Brute Force Check
        if "login" in request.url.path and request.method == "POST":
            # Check if IP is blocked
            blocked = await redis_client.get(f"login_block:{client_ip}")
            if blocked:
                from fastapi.responses import JSONResponse
                return JSONResponse({"detail": "Too many failed attempts"}, status_code=429)

        # Rule 2: Off-hours access
        current_hour = datetime.utcnow().hour
        # If doctor trying to access patient records in off hours:
        if current_hour in [0, 1, 2, 3, 4, 5] and "patient" in request.url.path:
            # Log AuditAnomaly('off_hours_access') asynchronously
            pass

        response = await call_next(request)
        
        # Post-Request Actions:
        
        # Failed login tracking
        if "login" in request.url.path and response.status_code == 401:
            failures = await redis_client.incr(f"login_fails:{client_ip}")
            if failures == 1:
                await redis_client.expire(f"login_fails:{client_ip}", 1800)
            if failures >= 5:
                await redis_client.set(f"login_block:{client_ip}", "1", ex=1800)
                # create Priority 4 alert dispatch

        # Rule 1: Access Spikes
        # ZADD audit_rate:{user_id} {timestamp} {nonce}
        # ZREMRANGEBYSCORE limit to last 5 mins
        # count. If > 50 -> AuditAnomaly
        
        return response
