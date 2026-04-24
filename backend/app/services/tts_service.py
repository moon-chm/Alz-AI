import tempfile
import os
import httpx
import base64
from gtts import gTTS
from app.utils.language import get_gtts_language
from app.services.cloudinary_service import upload_audio
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Sarvam supports hi-IN, en-IN, mr-IN among others.
# Warm, Maternal Voices for SAATHI
SARVAM_LANGUAGES = {
    "Hindi": "hi-IN",
    "Marathi": "mr-IN",
    "English": "en-IN"
}

# Example speakers: meera, aditi, etc (assuming meera is a good maternal voice for Sarvam)
SPEAKER_NAME = "meera"

async def text_to_speech(text: str, language: str, slow: bool = False, patient_id: str = None) -> str:
    """
    Convert text to speech using Sarvam TTS API (Neural) or gTTS (Fallback).
    """
    api_key = getattr(settings, 'sarvam_api_key', None)
    tmp_path = None
    
    try:
        if api_key:
            target_lang = SARVAM_LANGUAGES.get(language, "en-IN")
            url = "https://api.sarvam.ai/text-to-speech"
            
            headers = {
                "api-subscription-key": api_key,
                "Content-Type": "application/json"
            }
            
            # Use bulbul:v1 or v3 based on what is available, usually bulbul:v1
            data = {
                "inputs": [text],
                "target_language_code": target_lang,
                "speaker": SPEAKER_NAME,
                "pitch": 0,
                "pace": 0.9 if slow else 1.0,
                "loudness": 1.5,
                "speech_sample_rate": 8000,
                "enable_preprocessing": True,
                "model": "bulbul:v1"
            }

            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(url, json=data, headers=headers)
                if response.status_code == 200:
                    result = response.json()
                    audio_b64 = result.get("audios", [])[0] if result.get("audios") else None
                    if audio_b64:
                        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
                            tmp_path = tmp.name
                            tmp.write(base64.b64decode(audio_b64))
                            logger.info(f"✅ SAATHI: Neural voice generated via Sarvam ({target_lang})")
                    else:
                        logger.warning("Empty audio array from Sarvam, falling back to gTTS")
                        tmp_path = await _generate_gtts(text, language, slow)
                else:
                    logger.warning(f"⚠️ Sarvam failed ({response.status_code}: {response.text}), falling back to gTTS")
                    tmp_path = await _generate_gtts(text, language, slow)
        else:
            # 2. Standard gTTS Path
            tmp_path = await _generate_gtts(text, language, slow)

        audio_url = await upload_audio(tmp_path)
        return audio_url

    except Exception as e:
        logger.error(f"TTS error: {e}")
        return ""
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)

async def _generate_gtts(text: str, language: str, slow: bool) -> str:
    lang_code = get_gtts_language(language)
    with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as tmp:
        tmp_path = tmp.name
        tts = gTTS(text=text, lang=lang_code, slow=slow)
        tts.save(tmp_path)
    return tmp_path
