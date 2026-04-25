import uuid
from datetime import datetime
from sqlalchemy import Column, Float, String, DateTime, ForeignKey, Boolean, Integer
from sqlalchemy.dialects.postgresql import UUID, JSONB
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
    speed = Column(Float, nullable=True)
    entropy_score = Column(Float, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)

    # Relationship
    patient = relationship("Patient", foreign_keys=[patient_id])

class GeofenceZone(Base):
    __tablename__ = "geofence_zones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    name = Column(String, nullable=False)
    zone_type = Column(String, nullable=False) # safe, buffer, danger
    coordinates = Column(JSONB, nullable=False)
    priority = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    patient = relationship("Patient", foreign_keys=[patient_id])
