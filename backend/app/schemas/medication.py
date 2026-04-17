from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from uuid import UUID

class MedicationCreate(BaseModel):
    patient_id: UUID
    name: str
    dosage: str
    scheduled_times: List[str]
    tablet_photo_url: Optional[str] = None

class MedicationUpdate(BaseModel):
    name: Optional[str] = None
    dosage: Optional[str] = None
    scheduled_times: Optional[List[str]] = None
    tablet_photo_url: Optional[str] = None
    is_active: Optional[bool] = None

class MedicationResponse(BaseModel):
    id: UUID
    patient_id: UUID
    name: str
    dosage: str
    scheduled_times: List[str]
    tablet_photo_url: Optional[str] = None
    is_active: bool
    created_by: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True

class ComplianceGridDay(BaseModel):
    date: str
    taken: bool
    scheduled: bool

class ComplianceGrid(BaseModel):
    medication_name: str
    days: List[ComplianceGridDay]
