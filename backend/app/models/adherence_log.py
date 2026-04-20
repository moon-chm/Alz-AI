import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.postgres import Base
import enum

class AdherenceStatus(enum.Enum):
    taken = "taken"
    missed = "missed"
    skipped = "skipped"

class AdherenceLog(Base):
    __tablename__ = "adherence_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    medication_id = Column(UUID(as_uuid=True), ForeignKey("medications.id"), nullable=False)
    scheduled_time = Column(String, nullable=False) # e.g. "08:00"
    status = Column(Enum(AdherenceStatus), default=AdherenceStatus.taken)
    confirmed_at = Column(DateTime, default=datetime.utcnow)
    confirmed_date = Column(String, nullable=False) # YYYY-MM-DD for localized daily idempotency
    
    # Relationships
    patient = relationship("Patient")
    medication = relationship("Medication")

    __table_args__ = (
        UniqueConstraint('patient_id', 'medication_id', 'scheduled_time', 'confirmed_date', name='uix_adherence_daily'),
    )
