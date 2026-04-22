from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
from uuid import UUID

class CaretakerDashboard(BaseModel):
    patient_status: str
    patient_name: str
    patient_id: str
    recent_alerts: List[dict]
    medication_compliance_today: float
    last_saathi_time: Optional[datetime] = None
    last_vitals_time: Optional[datetime] = None
    primary_doctor_id: Optional[UUID] = None
    primary_doctor_name: Optional[str] = None

class PatientStatusResponse(BaseModel):
    status: str # 'green' | 'amber' | 'red'
    reason: str
    updated_at: datetime

class GeofenceSet(BaseModel):
    coordinates: List[Dict[str, float]] # list of {lat, lng}

class VitalsCreate(BaseModel):
    patient_id: UUID
    hr: int
    spo2: int
    steps: int
    sleep: float # Hours
    hrv: Optional[float] = None
    recorded_at: Optional[datetime] = None

class VitalsResponse(BaseModel):
    hr: int
    spo2: int
    steps: int
    sleep: float
    hrv: Optional[float] = None
    recorded_at: datetime

class PhotoResponse(BaseModel):
    id: UUID
    cloudinary_url: str
    caption: Optional[str] = None
    sender_name: str
    relationship: Optional[str] = None
    sent_at: datetime
    
    class Config:
        from_attributes = True

class AppointmentCreate(BaseModel):
    patient_id: UUID
    doctor_id: UUID
    scheduled_at: datetime
    notes: Optional[str] = None

class AppointmentResponse(BaseModel):
    id: UUID
    patient_id: UUID
    doctor_id: UUID
    scheduled_at: datetime
    status: str
    notes: Optional[str] = None
    doctor_name: str
    
    class Config:
        from_attributes = True

class WellnessInsightsResponse(BaseModel):
    score: int
    status: str
    insights: List[str]
    last_updated: datetime
