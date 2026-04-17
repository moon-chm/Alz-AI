import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Date, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_unique_id = Column(String, unique=True, nullable=False, index=True)
    full_name = Column(String, nullable=False)
    dob = Column(Date, nullable=False)
    level = Column(Integer, nullable=False, default=1)
    language = Column(String, nullable=False, default="Hindi")
    trusted_phone = Column(String, nullable=False)
    doctor_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Nexus 2.0 migration support
    is_legacy_id = Column(Boolean, default=False)

    # Relationships
    doctor = relationship("User", back_populates="patients", foreign_keys="[Patient.doctor_id]")
    caretaker_links = relationship("CaretakerPatient", back_populates="patient", foreign_keys="[CaretakerPatient.patient_id]")
    medications = relationship("Medication", back_populates="patient")
    appointments = relationship("Appointment", back_populates="patient", foreign_keys="[Appointment.patient_id]")
    alerts = relationship("Alert", back_populates="patient")
    photos = relationship("Photo", back_populates="patient")


class CaretakerPatient(Base):
    __tablename__ = "caretaker_patient"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    caretaker_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    relationship_type = Column(String, nullable=False)
    is_primary = Column(Boolean, default=False)
    escalation_order = Column(Integer, default=1)
    linked_at = Column(DateTime, default=datetime.utcnow)
    verified_at = Column(DateTime, nullable=True) # Successfully verified via trusted_phone

    # Relationships
    caretaker = relationship("User", back_populates="caretaker_patient_links", foreign_keys="[CaretakerPatient.caretaker_id]")
    patient = relationship("Patient", back_populates="caretaker_links", foreign_keys="[CaretakerPatient.patient_id]")
