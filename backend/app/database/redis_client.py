import redis
from app.config import settings

def get_redis():
    try:
        # Defaulting to localhost for local dev if REDIS_URL not present
        pool = redis.ConnectionPool.from_url(
            getattr(settings, 'redis_url', 'redis://localhost:6379/0'), 
            decode_responses=True
        )
        return redis.Redis(connection_pool=pool)
    except Exception as e:
        print(f"Failed to connect to Redis: {e}")
        return None

redis_client = get_redis()
