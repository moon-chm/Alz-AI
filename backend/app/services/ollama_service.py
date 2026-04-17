import httpx
import logging
import asyncio
from app.config import settings

logger = logging.getLogger(__name__)

async def call_ollama(
    system_prompt: str, 
    user_message: str,
    conversation_history: list = None,
    timeout: float = 30.0
) -> str:
    """
    Call local Ollama API via httpx.
    Connects to host.docker.internal:11434.
    """
    url = f"{settings.ollama_api_base}/api/chat"
    
    messages = [{"role": "system", "content": system_prompt}]
    if conversation_history:
        messages.extend(conversation_history)
    messages.append({"role": "user", "content": user_message})
    
    payload = {
        "model": settings.ollama_model,
        "messages": messages,
        "stream": False,
        "options": {
            "temperature": 0.7,
            "num_predict": 500
        }
    }
    
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            return data["message"]["content"].strip()
    except Exception as e:
        logger.error(f"Ollama API error: {e}")
        raise

async def is_ollama_alive() -> bool:
    """Check if Ollama server is reachable."""
    url = f"{settings.ollama_api_base}/api/tags"
    try:
        async with httpx.AsyncClient(timeout=2.0) as client:
            response = await client.get(url)
            return response.status_code == 200
    except:
        return False
