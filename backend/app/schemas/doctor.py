from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from uuid import UUID

class PatientSummary(BaseModel):
    id: UUID
    patient_unique_id: str
    full_name: str
    level: int
    language: str
    urgency: str # 'red' | 'amber' | 'green'
    last_mood: str
    last_checkin: Optional[datetime] = None

class DoctorDashboard(BaseModel):
    patients: List[PatientSummary]
    total: int
    critical_count: int

class MRIUploadResponse(BaseModel):
    result: str
    confidence: float
    timestamp: datetime

class AnalyticsResponse(BaseModel):
    steps: List[dict]
    heartrate: List[dict]
    sleep: List[dict]
    medication_compliance: List[dict]
    voice_rate: dict
