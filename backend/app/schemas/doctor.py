from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime
from uuid import UUID

class PatientSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
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

class MRIScanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    scan_id: UUID
    task_id: str
    status: str
    message: str

class MRIAnalysisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    scan_id: UUID
    history_id: Optional[UUID] = None
    model_version: str
    predicted_level: int
    confidence: float
    is_uncertain: bool
    probabilities: dict
    analyzed_at: datetime

class MRIStatusResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    task_id: str
    status: str # 'PENDING', 'STARTED', 'SUCCESS', 'FAILURE'
    scan_id: Optional[UUID] = None
    result: Optional[MRIAnalysisResponse] = None
    error: Optional[str] = None

class MRIConfirmationRequest(BaseModel):
    history_id: UUID
    confirm: bool
    doctor_note: Optional[str] = None

class TeleconsultCreateRequest(BaseModel):
    patient_id: UUID
    start_time: datetime
    duration_minutes: int = 30
    note: Optional[str] = None

class AnalyticsResponse(BaseModel):
    steps: List[dict]
    heartrate: List[dict]
    sleep: List[dict]
    medication_compliance: List[dict]
    voice_rate: dict

class MRIScanHistoryItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    scan_id: UUID
    created_at: datetime
    status: str
    predicted_level: Optional[int] = None
    confidence: Optional[float] = None
    model_version: Optional[str] = None

class MRIHistoryResponse(BaseModel):
    items: List[MRIScanHistoryItem]
    total: int
    page: int
    pages: int
