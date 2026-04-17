import time
import logging
import asyncio
from app.services import ollama_service, groq_service
from app.config import settings

logger = logging.getLogger(__name__)

async def generate_response(
    system_prompt: str,
    user_message: str,
    conversation_history: list = None
) -> dict:
    """
    AI Orchestrator: Local-First with Hybrid Fallback.
    Routes requests to Ollama (primary) or Groq (fallback).
    """
    start_time = time.time()
    provider = "ollama"
    fallback_reason = None
    response_text = ""

    try:
        # 1. Attempt Primary (Ollama)
        logger.info(f"🧠 AI: Starting local inference via {settings.ollama_model}...")
        
        # We wrap the call in a wait_for to enforce the user's latency threshold
        try:
            response_text = await asyncio.wait_for(
                ollama_service.call_ollama(system_prompt, user_message, conversation_history),
                timeout=settings.latency_threshold
            )
            
            if not response_text:
                raise ValueError("Empty response from Ollama")

        except (asyncio.TimeoutError, Exception) as e:
            provider = "groq"
            fallback_reason = "latency_exceeded" if isinstance(e, asyncio.TimeoutError) else str(e)
            logger.warning(f"⚠️ AI: Local inference failed or timed out. Falling back to Groq. Reason: {fallback_reason}")
            
            # 2. Attempt Fallback (Groq)
            response_text = await groq_service.call_groq(system_prompt, user_message, conversation_history)
            
    except Exception as e:
        logger.error(f"❌ AI: Total failure in AI orchestration: {e}")
        response_text = "I'm having a little trouble connecting right now, but I'm here for you. How are you feeling?"
        provider = "error_fallback"

    latency = round(time.time() - start_time, 2)
    
    # 📋 Observability Logging (MANDATORY per Requirements)
    logger.info(
        f"📊 AI_EXECUTION: provider={provider} | latency={latency}s | "
        f"fallback={fallback_reason if fallback_reason else 'None'} | "
        f"model='{settings.ollama_model if provider == 'ollama' else settings.groq_model}'"
    )

    return {
        "text": response_text,
        "provider": provider,
        "latency": latency,
        "fallback_reason": fallback_reason
    }
