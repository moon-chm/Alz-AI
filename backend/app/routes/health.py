from fastapi import APIRouter
from app.database.postgres import engine
from app.database.neo4j import driver
from app.config import settings
import redis

router = APIRouter(tags=["health"])

@router.get("")
async def health_check():
    status = {"status": "ok", "service": "alz-ai-backend"}
    
    # PostgreSQL
    try:
        from sqlalchemy import text
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        status["postgres"] = True
    except:
        status["postgres"] = False
    
    # Neo4j
    try:
        with driver.session() as session:
            session.run("RETURN 1")
        status["neo4j"] = True
    except:
        status["neo4j"] = False
    
    # Redis
    try:
        r = redis.from_url(settings.redis_url)
        r.ping()
        status["redis"] = True
    except:
        status["redis"] = False
    
    # AI Providers
    status["groq"] = bool(settings.groq_api_key)
    status["elevenlabs"] = bool(settings.elevenlabs_api_key)
    status["cloudinary"] = bool(settings.cloudinary_url)
    
    return status
