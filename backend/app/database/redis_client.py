import redis
from app.config import settings

def get_redis():
    # Attempt connection with settings.redis_url which defaults to 'redis://redis:6379' in Docker
    # or use direct fallback string
    url = getattr(settings, 'redis_url', 'redis://redis:6379/0')
    try:
        pool = redis.ConnectionPool.from_url(url, decode_responses=True)
        r = redis.Redis(connection_pool=pool)
        r.ping() # Verify connectivity on init
        return r
    except Exception as e:
        print(f"Warning: Redis connection failed on {url}: {e}")
        return None

redis_client = get_redis()
