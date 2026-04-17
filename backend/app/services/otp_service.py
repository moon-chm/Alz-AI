import redis
import random
import string
import hashlib
import json
import logging
import hmac
from datetime import datetime, timedelta
from app.config import settings
from app.services import twilio_service

logger = logging.getLogger(__name__)

# Redis Client Setup
try:
    r = redis.from_url(settings.redis_url, decode_responses=True)
except Exception as e:
    r = None
    logger.warning(f"Redis not available: {e}. OTP will be unreliable.")

def _hash_otp(otp: str) -> str:
    """Hash OTP for secure storage."""
    return hashlib.sha256(otp.encode()).hexdigest()

async def generate_otp(phone: str) -> str:
    """
    Generate, hash, and store OTP in Redis with attempt tracking.
    Enforces DEMO mode (fixed OTP) and PRODUCTION mode (real SMS).
    """
    key = f"otp:{phone}"
    limit_key = f"otp_limit:{phone}"
    
    # 1. Rate Limiting Check (Production only)
    if settings.system_mode == "PRODUCTION" and r:
        req_count = r.get(limit_key)
        if req_count and int(req_count) >= 3:
            logger.warning(f"Rate limit exceeded for {phone}")
            raise ValueError("Too many requests. Please try again in 10 minutes.")
        r.incr(limit_key)
        r.expire(limit_key, 600) # 10 min window

    # 2. OTP Generation
    if settings.system_mode == "DEMO" or settings.otp_mode == "MOCK":
        otp = "123456"
        logger.info(f"[NEXUS-DEMO] Fixed OTP assigned for {phone}: {otp}")
    else:
        otp = ''.join(random.choices(string.digits, k=6))
        
    # 3. Secure Storage
    expiry_ts = datetime.utcnow() + timedelta(minutes=settings.otp_expiry_mins)
    data = {
        "hash": _hash_otp(otp),
        "expires_at": expiry_ts.isoformat(),
        "attempts": 0
    }
    
    if r:
        r.setex(key, settings.otp_expiry_mins * 60, json.dumps(data))
    
    # 4. Delivery
    if settings.system_mode == "PRODUCTION" and settings.otp_mode == "REAL":
        message = f"[Alz-AI] Your security verification code is: {otp}. Valid for {settings.otp_expiry_mins} mins. Do not share it."
        await twilio_service.send_sms(phone, message)
    
    return otp

def verify_otp(phone: str, otp: str) -> bool:
    """
    Verify OTP with hash comparison and attempt tracking.
    Deletes on success.
    """
    if not r:
        return settings.system_mode == "DEMO" and otp == "123456"
        
    key = f"otp:{phone}"
    stored_data = r.get(key)
    
    if not stored_data:
        return False
        
    data = json.loads(stored_data)
    
    # 1. Check Expiry
    if datetime.fromisoformat(data["expires_at"]) < datetime.utcnow():
        r.delete(key)
        return False
        
    # 2. Check Attempts
    if data["attempts"] >= settings.otp_max_attempts:
        r.delete(key)
        logger.warning(f"Max attempts reached for {phone}")
        return False
        
    # 3. Verify Hash (Using constant-time comparison)
    provided_hash = _hash_otp(otp.strip())
    if hmac.compare_digest(data["hash"], provided_hash):
        r.delete(key)
        logger.info(f"OTP verified successfully for {phone}")
        return True
    
    # 4. Increment Attempts on Failure
    data["attempts"] += 1
    r.setex(key, settings.otp_expiry_mins * 60, json.dumps(data))
    return False

def is_otp_pending(phone: str) -> bool:
    if not r: return False
    return r.exists(f"otp:{phone}") > 0
