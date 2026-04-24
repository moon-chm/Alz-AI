import httpx
import logging
from app.config import settings

logger = logging.getLogger(__name__)

class VoiceCloningService:
    def __init__(self):
        self.api_key = settings.elevenlabs_api_key
        self.base_url = "https://api.elevenlabs.io/v1"

    async def clone_voice(self, name: str, audio_content: bytes, description: str = "") -> str:
        """
        Creates an Instant Voice Clone using ElevenLabs.
        Returns the cloned voice_id.
        """
        if not self.api_key:
            logger.error("ElevenLabs API Key missing")
            return None

        url = f"{self.base_url}/voices/add"
        headers = {
            "xi-api-key": self.api_key
        }
        
        files = {
            'files': ('sample.mp3', audio_content, 'audio/mpeg')
        }
        
        data = {
            'name': name,
            'description': description or f"Cloned voice for Alzheimer's patient companion",
            'labels': '{"type": "alzai_clone"}'
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, headers=headers, data=data, files=files)
                if response.status_code == 200:
                    voice_id = response.json().get("voice_id")
                    logger.info(f"✅ ElevenLabs: Voice cloned successfully. ID: {voice_id}")
                    return voice_id
                else:
                    logger.error(f"❌ ElevenLabs: Voice cloning failed ({response.status_code}): {response.text}")
                    return None
            except Exception as e:
                logger.error(f"❌ ElevenLabs: Network error during cloning: {e}")
                return None

    async def delete_cloned_voice(self, voice_id: str):
        """Removes a voice from ElevenLabs to free up slots"""
        if not self.api_key or not voice_id:
            return

        url = f"{self.base_url}/voices/{voice_id}"
        headers = {"xi-api-key": self.api_key}

        async with httpx.AsyncClient() as client:
            try:
                resp = await client.delete(url, headers=headers)
                if resp.status_code == 200:
                    logger.info(f"✅ ElevenLabs: Deleted voice {voice_id}")
                else:
                    logger.warning(f"⚠️ ElevenLabs: Failed to delete voice {voice_id}: {resp.text}")
            except Exception as e:
                logger.error(f"❌ ElevenLabs: Error deleting voice: {e}")

voice_cloning_service = VoiceCloningService()
