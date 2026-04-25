import httpx
import logging
import numpy as np
from app.config import settings

logger = logging.getLogger(__name__)

async def get_embedding(text: str) -> list[float]:
    """
    Get embedding vector from Ollama.
    """
    url = f"{settings.ollama_api_base}/api/embeddings"
    payload = {
        "model": settings.ollama_model, # Ensure the model supports embeddings (most do)
        "prompt": text
    }
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            return response.json()["embedding"]
    except Exception as e:
        logger.error(f"Failed to get embedding: {e}")
        return []

def cosine_similarity(v1: list[float], v2: list[float]) -> float:
    """
    Calculate cosine similarity between two vectors.
    """
    if not v1 or not v2:
        return 0.0
    
    v1 = np.array(v1)
    v2 = np.array(v2)
    
    dot_product = np.dot(v1, v2)
    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)
    
    if norm_v1 == 0 or norm_v2 == 0:
        return 0.0
        
    return float(dot_product / (norm_v1 * norm_v2))
