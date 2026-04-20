import uuid
from datetime import datetime
import enum
from sqlalchemy import Column, String, Boolean, DateTime, Time, Enum, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class RoleEnum(str, enum.Enum):
    doctor = "doctor"
    caretaker = "caretaker"

class UserStatus(str, enum.Enum):
    pending = "pending"
    active = "active"
    rejected = "rejected"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    role = Column(Enum(RoleEnum), nullable=False)
    full_name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    
    # Doctor specific fields
    nmc_number = Column(String, nullable=True)
    specialization = Column(String, nullable=True)
    hospital_name = Column(String, nullable=True)
    
    # Verification and status
    status = Column(Enum(UserStatus), default=UserStatus.pending)
    under_dispute = Column(Boolean, default=False)
    
    device_fingerprint = Column(String, nullable=True)
    dnd_start = Column(Time, nullable=True)
    dnd_end = Column(Time, nullable=True)
    
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        Index("idx_user_nmc", "nmc_number"),
    )

    # Relationships
    patients = relationship("Patient", back_populates="doctor", foreign_keys="[Patient.doctor_id]")
    caretaker_patient_links = relationship("CaretakerPatient", back_populates="caretaker", foreign_keys="[CaretakerPatient.caretaker_id]")

    @property
    def is_verified(self):
        return self.status == UserStatus.active
