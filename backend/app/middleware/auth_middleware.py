from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.config import settings

class DeviceBindingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # We assume JWT decode already happens implicitly or natively mapped earlier
        # Pseudocode validation for Patient device binding
        if "/patient" in request.url.path or "saathi" in request.url.path:
            fingerprint = request.headers.get("x-device-fingerprint")
            patient_id = "extracted_from_jwt" # placeholder
            
            # 1) If user.device_fingerprint is None -> Set it to fingerprint
            # 2) If fingerprint != user.device_fingerprint:
            # 3) create AuditAnomaly record
            # 4) send twilio alert
            # return Response(content="Forbidden", status_code=403)
            pass
            
        return await call_next(request)
