import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Enum, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class AppointmentStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    completed = "completed"
    cancelled = "cancelled"

class TeleconsultMode(str, enum.Enum):
    in_person = "in_person"
    teleconsult = "teleconsult"

class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    doctor_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    caretaker_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    scheduled_at = Column(DateTime, nullable=False)
    status = Column(Enum(AppointmentStatus), default=AppointmentStatus.pending)
    mode = Column(Enum(TeleconsultMode), default=TeleconsultMode.in_person)
    meeting_url = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    reminder_sent = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    patient = relationship("Patient", back_populates="appointments", foreign_keys=[patient_id])
    doctor = relationship("User", foreign_keys=[doctor_id])
    caretaker = relationship("User", foreign_keys=[caretaker_id])
