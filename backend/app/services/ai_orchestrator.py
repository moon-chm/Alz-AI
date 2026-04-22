import time
import logging
import asyncio
import json
import random
from app.services import ollama_service, groq_service
from app.config import settings
from app.database.redis_client import redis_client

logger = logging.getLogger(__name__)

async def generate_response(
    system_prompt: str,
    user_message: str,
    patient_id: str = None,
    conversation_history: list = None
) -> dict:
    """
    AI Orchestrator: Local-First with Hybrid Fallback.
    Routes requests to Ollama (primary) or Groq (fallback).
    Includes Redis-based recovery for high-reliability.
    """
    start_time = time.time()
    provider = "ollama"
    fallback_reason = None
    response_text = ""

    try:
        # 1. Attempt Primary (Ollama)
        try:
            response_text = await asyncio.wait_for(
                ollama_service.call_ollama(system_prompt, user_message, conversation_history),
                timeout=settings.latency_threshold
            )
            if not response_text:
                raise ValueError("Empty response from Ollama")
        except (asyncio.TimeoutError, Exception) as e:
            provider = "groq"
            fallback_reason = "latency_exceeded" if isinstance(e, asyncio.TimeoutError) else f"ollama_error: {str(e)}"
            
            # 2. Attempt Fallback (Groq)
            try:
                response_text = await groq_service.call_groq(system_prompt, user_message, conversation_history)
            except Exception as ge:
                logger.error(f"❌ AI: Fallback to Groq also failed: {ge}")
                raise # Re-raise to trigger Redis recovery
        
        # 3. Success — Update Cache
        if response_text and patient_id and redis_client:
            redis_client.set(f"saathi:last_res:{patient_id}", response_text, ex=86400) # 24h cache

    except Exception as e:
        logger.error(f"❌ AI: Orchestration total failure: {e}")
        provider = "error_fallback"
        fallback_reason = f"total_failure: {str(e)}"

        # 4. Recovery Attempt (Redis Cache)
        if patient_id and redis_client:
            cached = redis_client.get(f"saathi:last_res:{patient_id}")
            if cached:
                logger.info(f"💾 AI: Recovered last successful response from cache for {patient_id}")
                response_text = cached
            else:
                response_text = _get_safety_response()
        else:
            response_text = _get_safety_response()

    latency = round(time.time() - start_time, 2)
    
    logger.info(
        f"📊 AI_EXECUTION: provider={provider} | latency={latency}s | "
        f"fallback={fallback_reason if fallback_reason else 'None'}"
    )

    return {
        "text": response_text,
        "provider": provider,
        "latency": latency,
        "fallback_reason": fallback_reason
    }

def _get_safety_response() -> str:
    safety_responses = [
        "I'm here, dear. Just taking a moment to breathe. How are you feeling right now?",
        "I'm listening. Sometimes I get a little lost in thought, but I'm always with you. Tell me more about your day.",
        "Everything is alright. I'm right here. Is there anything on your mind?",
        "I'm always here for you. Why don't we just spend a quiet moment together?"
    ]
    return random.choice(safety_responses)
