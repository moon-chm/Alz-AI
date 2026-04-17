import tempfile
import os
from gtts import gTTS
from app.utils.language import get_gtts_language
from app.services.cloudinary_service import upload_audio
import logging

logger = logging.getLogger(__name__)

async def text_to_speech(text: str, language: str, slow: bool = False) -> str:
    """
    Convert text to speech using gTTS.
    Uploads to Cloudinary, returns audio URL.
    Deletes temp file after upload.
    slow=True for agitated mood (softer/slower delivery).
    """
    lang_code = get_gtts_language(language)
    tmp_path = None
    try:
        tts = gTTS(text=text, lang=lang_code, slow=slow)
        with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as tmp:
            tmp_path = tmp.name
            tts.save(tmp_path)
        
        audio_url = await upload_audio(tmp_path)
        return audio_url
    except Exception as e:
        logger.error(f"TTS error: {e}")
        raise
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)
