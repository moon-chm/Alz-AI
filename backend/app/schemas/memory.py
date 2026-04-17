from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class MemoryCreate(BaseModel):
    patient_id: str
    content: str
    category: str
    date_added: Optional[str] = None
    added_by: str

class MemoryUpdate(BaseModel):
    content: Optional[str] = None
    category: Optional[str] = None

class MemoryResponse(BaseModel):
    id: str
    patient_id: str
    content: str
    category: str
    date_added: str
    added_by: str

class FamilyMemberCreate(BaseModel):
    patient_id: str
    name: str
    relationship: str
    phone: str

class FamilyMemberResponse(BaseModel):
    id: str
    name: str
    relationship: str
    phone: str
    face_encoding_path: Optional[str] = None

class MoodLogResponse(BaseModel):
    mood: str
    timestamp: str
    summary: str
    detected_by: str

class ConversationLogResponse(BaseModel):
    timestamp: str
    summary: str
    mood_detected: str
    initiated_by: str
