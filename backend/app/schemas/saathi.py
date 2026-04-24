from pydantic import BaseModel
from typing import Optional

class SAATHITalkResponse(BaseModel):
    response: str
    audio_url: str
    mood: str

class CheckInRequest(BaseModel):
    patient_id: str

class SAATHIContext(BaseModel):
    system_prompt: str
    token_count: int
