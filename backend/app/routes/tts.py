from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from app.services import tts_service
from app.utils.jwt import get_current_user
from app.models.user import User

router = APIRouter(tags=["tts"])

class TTSRequest(BaseModel):
    text: str
    language: str = "English"
    slow: bool = False
    patient_id: str = None

@router.post("/generate")
async def generate_tts(request: TTSRequest):
    """
    General TTS endpoint that uses the official SAATHI voice.
    """
    if not request.text:
        raise HTTPException(400, "Text is required")
        
    url = await tts_service.text_to_speech(
        request.text, 
        request.language, 
        slow=request.slow,
        patient_id=request.patient_id
    )
    
    if not url:
        raise HTTPException(500, "TTS generation failed")
        
    return {"url": url}
