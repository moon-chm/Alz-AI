import uuid
from datetime import datetime
from sqlalchemy import Column, Float, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class LocationLog(Base):
    __tablename__ = "location_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    accuracy = Column(Float, nullable=True)
    provider = Column(String, nullable=True) # gps, network, etc
    timestamp = Column(DateTime, default=datetime.utcnow)

    # Relationship
    patient = relationship("Patient", foreign_keys=[patient_id])
