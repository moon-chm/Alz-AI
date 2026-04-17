import asyncio
from groq import Groq
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Initialize client conditionally to avoid breaking import before settings are ready if this is imported early
client = None
if settings.groq_api_key:
    client = Groq(api_key=settings.groq_api_key)

async def call_groq(
    system_prompt: str, 
    user_message: str,
    conversation_history: list = None,
    max_tokens: int = 500
) -> str:
    """
    Call Groq API with retry logic.
    Retries 3 times with exponential backoff on rate limit.
    Returns response text.
    """
    if not client:
        raise ValueError("Groq API key not configured")
        
    messages = [{"role": "system", "content": system_prompt}]
    if conversation_history:
        messages.extend(conversation_history)
    messages.append({"role": "user", "content": user_message})
    
    for attempt in range(3):
        try:
            response = client.chat.completions.create(
                model=settings.groq_model,  # llama-3.3-70b-versatile
                messages=messages,
                max_tokens=max_tokens,
                temperature=0.7,
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            if "rate_limit" in str(e).lower() and attempt < 2:
                wait_time = (attempt + 1) ** 2  # 1s, 4s
                logger.warning(f"Groq rate limit, retrying in {wait_time}s")
                await asyncio.sleep(wait_time)
            else:
                logger.error(f"Groq API error: {e}")
                raise
    raise Exception("Groq API failed after 3 retries")
