import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class Medication(Base):
    __tablename__ = "medications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    name = Column(String, nullable=False)
    dosage = Column(String, nullable=False)
    scheduled_times = Column(JSON, nullable=False) # e.g. ["08:00", "14:00"]
    tablet_photo_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    patient = relationship("Patient", back_populates="medications", foreign_keys=[patient_id])
    creator = relationship("User", foreign_keys=[created_by])
