from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    # bcxrypt cannot handle passwords > 72 bytes. Safely truncate if users paste massive strings during testing
    return pwd_context.hash(password[:71])

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
