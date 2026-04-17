from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import date, datetime
from uuid import UUID
from app.schemas.auth import UserResponse

class PatientCreate(BaseModel):
    full_name: str
    dob: date
    level: int = Field(ge=1, le=3)
    language: str = "Hindi"
    trusted_phone: str

class PatientResponse(BaseModel):
    id: UUID
    patient_unique_id: str
    full_name: str
    dob: date
    level: int
    language: str
    trusted_phone: str
    doctor_id: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True

class PatientProfile(PatientResponse):
    doctor_info: Optional[UserResponse] = None
    caretaker_info: Optional[List[UserResponse]] = None

class PatientLevelUpdate(BaseModel):
    level: int = Field(ge=1, le=3)

class FamilyMemberResponse(BaseModel):
    name: str
    relationship: str
    phone: str

class SOSTrigger(BaseModel):
    patient_id: Optional[str] = None
    lat: float
    lng: float

class MedicationConfirm(BaseModel):
    medication_id: UUID
