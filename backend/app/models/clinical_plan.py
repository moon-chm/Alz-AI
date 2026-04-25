import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class ClinicalPlan(Base):
    __tablename__ = "clinical_plans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    type = Column(String, nullable=False) # "exercise", "diet"
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    scheduled_times = Column(JSON, nullable=False) # e.g. ["08:00"]
    is_active = Column(Boolean, default=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", foreign_keys=[patient_id])
    creator = relationship("User", foreign_keys=[created_by])
