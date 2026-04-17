from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        case_sensitive=False,
        extra='ignore'
    )

    postgres_url: str
    neo4j_uri: str
    neo4j_username: str
    neo4j_password: str
    jwt_secret_key: str
    jwt_algorithm: str = 'HS256'
    jwt_expire_minutes: int = 480
    groq_api_key: str
    groq_model: str = 'llama-3.3-70b-versatile'
    whisper_model: str = 'base'
    twilio_account_sid: str
    twilio_auth_token: str
    twilio_whatsapp_from: str
    twilio_from_number: str = ""
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""
    redis_url: str = 'redis://redis:6379'

    # ✅ Infrastructure Fields (Docker/Local)
    postgres_user: str = "alzai"
    postgres_password: str = "alzai_secure_password"
    postgres_db: str = "alzai"
    
    minio_root_user: str = "admin"
    minio_root_password: str = "minio_admin_secure"
    minio_endpoint: str = "http://minio:9000"
    minio_bucket: str = "alzai-media"
    
    ollama_api_base: str = "http://host.docker.internal:11434"
    ollama_model: str = "phi3"
    
    # ─── SYSTEM MODES ──────────────────────────────────────────
    system_mode: str = "DEMO"  # "DEMO" or "PRODUCTION"
    otp_mode: str = "MOCK"     # "MOCK" or "REAL"
    doctor_auto_activate: bool = True
    
    # ─── SECURITY PARAMETERS ────────────────────────────────────
    otp_expiry_mins: int = 5
    otp_max_attempts: int = 3

    # AI Orchestration
    latency_threshold: float = 8.0  # Seconds
    preferred_ai_provider: str = 'ollama'  # 'ollama' or 'groq'


@lru_cache()
def get_settings():
    return Settings()

settings = get_settings()
