import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey, Date
from sqlalchemy.dialects.postgresql import UUID, JSON
from app.database.postgres import Base

class PatientMetric(Base):
    __tablename__ = "patient_metrics"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    recorded_date = Column(Date, default=datetime.utcnow().date(), nullable=False)
    
    # 0-100 scores
    wellness_score = Column(Integer, default=0)
    med_adherence_percent = Column(Integer, default=0)
    habit_completion_percent = Column(Integer, default=0)
    exercise_completion_percent = Column(Integer, default=0)
    diet_adherence_percent = Column(Integer, default=0)
    
    # Cognitive / Brain Health (from games)
    cognitive_score = Column(Integer, default=0) # Average performance across games
    
    # Metadata for specific insights
    insights = Column(JSON, default={})
    
    created_at = Column(DateTime, default=datetime.utcnow)
