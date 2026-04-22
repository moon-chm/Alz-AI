import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship as sa_relationship
from app.database.postgres import Base

class Vitals(Base):
    __tablename__ = "vitals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    
    hr = Column(Integer, nullable=False)
    spo2 = Column(Integer, nullable=False)
    steps = Column(Integer, nullable=False, default=0)
    sleep = Column(Float, nullable=False, default=0.0) # Hours
    hrv = Column(Float, nullable=True) # Heart Rate Variability
    
    recorded_at = Column(DateTime, default=datetime.utcnow, index=True)

    # Relationships
    patient = sa_relationship("Patient", backref="vitals")
