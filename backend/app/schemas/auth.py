from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime
from uuid import UUID
from app.utils.validators import validate_indian_phone, validate_nmc_number

class DoctorRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str
    phone: str
    nmc_number: str
    specialization: Optional[str] = None
    hospital_name: Optional[str] = None

    @field_validator('phone')
    def validate_phone(cls, v):
        if not validate_indian_phone(v):
            raise ValueError("Invalid Indian phone number")
        return v

    @field_validator('nmc_number')
    def validate_nmc(cls, v):
        if not validate_nmc_number(v):
            raise ValueError("Invalid NMC number format")
        return v

class CaretakerRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str
    phone: str
    patient_unique_id: str

    @field_validator('phone')
    def validate_phone(cls, v):
        if not validate_indian_phone(v):
            raise ValueError("Invalid Indian phone number")
        return v

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    role: str
    user_id: str
    patient_id: Optional[str] = None
    is_mock: Optional[bool] = False

class RefreshRequest(BaseModel):
    refresh_token: str


class OTPSendRequest(BaseModel):
    phone: str

class OTPVerifyRequest(BaseModel):
    phone: str
    otp: str = Field(min_length=6, max_length=6)

class UnifiedOTPRequest(BaseModel):
    role: str # 'patient' or 'caretaker'
    identifier: str # PatientUniqueId or Phone

class UnifiedLoginRequest(BaseModel):
    role: str
    identifier: str
    otp: str = Field(min_length=6, max_length=6)

class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    full_name: str
    role: str
    phone: str
    is_verified: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class CaretakerRegisterResponse(BaseModel):
    user: UserResponse
    recipient_preview: str
