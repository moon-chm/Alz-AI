import whisper
from functools import lru_cache
import os
import logging
from app.config import settings

logger = logging.getLogger(__name__)

@lru_cache(maxsize=1)
def _load_model():
    logger.info(f"Loading Whisper model: {settings.whisper_model}")
    return whisper.load_model(settings.whisper_model)

async def transcribe_audio(audio_file_path: str) -> dict:
    """
    Transcribe audio file using Whisper.
    Returns {text, language, confidence}
    Deletes temp file after transcription.
    """
    try:
        model = _load_model()
        result = model.transcribe(audio_file_path, fp16=False)
        return {
            "text": result["text"].strip(),
            "language": result.get("language", "hi"),
            "confidence": 1.0  # Whisper doesn't return confidence directly
        }
    except Exception as e:
        logger.error(f"Whisper transcription error: {e}")
        raise
    finally:
        # Always delete temp file
        try:
            if os.path.exists(audio_file_path):
                os.remove(audio_file_path)
        except Exception:
            pass
