import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Float, Boolean, Integer, Text, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class ScanStatus(str, enum.Enum):
    pending = "pending"
    processing = "processing"
    completed = "completed"
    failed = "failed"

class SeveritySource(str, enum.Enum):
    mri_ai = "mri_ai"
    doctor_override = "doctor_override"
    initial_diagnosis = "initial_diagnosis"

class PatientMRIScan(Base):
    __tablename__ = "patient_mri_scans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False)
    doctor_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    
    filename = Column(String, nullable=False)
    storage_path = Column(String, nullable=False) # MinIO path
    checksum = Column(String, nullable=True)     # For deduplication
    
    status = Column(Enum(ScanStatus), default=ScanStatus.pending)
    metadata_json = Column(JSONB, nullable=True)  # scan_type, source, device_info
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    patient = relationship("Patient", back_populates="mri_scans")
    analysis = relationship("PatientMRIAnalysis", back_populates="scan", uselist=False, cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_mri_patient_id", "patient_id"),
        Index("idx_mri_status", "status"),
    )

class PatientMRIAnalysis(Base):
    __tablename__ = "patient_mri_analysis"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    scan_id = Column(UUID(as_uuid=True), ForeignKey("patient_mri_scans.id", ondelete="CASCADE"), nullable=False, unique=True)
    
    model_version = Column(String, nullable=False)
    predicted_level = Column(Integer, nullable=False) # 1-3
    confidence = Column(Float, nullable=False)
    is_uncertain = Column(Boolean, default=False)
    
    probabilities = Column(JSONB, nullable=True)      # Detailed probability mapping
    analysis_notes = Column(Text, nullable=True)
    
    analyzed_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    scan = relationship("PatientMRIScan", back_populates="analysis")

    __table_args__ = (
        Index("idx_analysis_scan_id", "scan_id"),
    )

class PatientSeverityHistory(Base):
    __tablename__ = "patient_severity_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id", ondelete="CASCADE"), nullable=False)
    
    level_before = Column(Integer, nullable=True)
    level_after = Column(Integer, nullable=False)
    
    source = Column(Enum(SeveritySource), nullable=False)
    reference_id = Column(UUID(as_uuid=True), nullable=True) # scan_id if mri_ai
    
    note = Column(Text, nullable=True)
    
    # Audit Flow (Mandatory per Safety Rule)
    is_confirmed = Column(Boolean, default=False)
    confirmed_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=True)
    confirmed_at = Column(DateTime, nullable=True)
    
    recorded_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    patient = relationship("Patient", back_populates="severity_history")
    confirmer = relationship("User")

    __table_args__ = (
        Index("idx_severity_patient_id", "patient_id"),
    )
