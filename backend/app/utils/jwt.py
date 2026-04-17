from datetime import datetime, timedelta
from jose import jwt, JWTError
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.config import settings
from app.database.postgres import get_db
from app.models.user import User
from app.database.redis_client import redis_client
import uuid

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta if expires_delta else timedelta(minutes=settings.jwt_expire_minutes))
    to_encode.update({"exp": expire, "type": "access", "jti": str(uuid.uuid4())})
    return jwt.encode(to_encode, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)

def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=7) # 7 days refresh
    to_encode.update({"exp": expire, "type": "refresh", "jti": str(uuid.uuid4())})
    return jwt.encode(to_encode, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)

def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
        jti = payload.get("jti")
        if redis_client and jti and redis_client.get(jti) == "blacklisted":
            raise JWTError("Token has been blacklisted")
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials or token expired",
            headers={"WWW-Authenticate": "Bearer"},
        )

def blacklist_token(token: str):
    try:
        payload = decode_token(token)
        jti = payload.get("jti")
        exp = payload.get("exp")
        if redis_client and jti and exp:
            ttl = int(exp - datetime.utcnow().timestamp())
            if ttl > 0:
                redis_client.setex(jti, ttl, "blacklisted")
    except HTTPException:
        pass # Already invalid

def get_current_user(request: Request, token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    # Support HTTP-only cookie extraction if header fails
    if not token:
        token = request.cookies.get("access_token")
        
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    payload = decode_token(token)
    if payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid token type")

    user_id: str = payload.get("sub")
    if user_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token missing subject")
        
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user

def require_doctor(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role.value != 'doctor' and current_user.role != 'doctor':
        raise HTTPException(status_code=403, detail="Not authorized, doctor role required")
    return current_user

def require_caretaker(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role.value != 'caretaker' and current_user.role != 'caretaker':
        raise HTTPException(status_code=403, detail="Not authorized, caretaker role required")
    return current_user
