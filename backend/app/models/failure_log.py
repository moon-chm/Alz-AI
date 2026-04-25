from sqlalchemy import Column, String, DateTime, JSON, ForeignKey
from app.database.postgres import Base
from datetime import datetime
import uuid

class FailureLog(Base):
    __tablename__ = "failure_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String, index=True)
    service = Column(String, index=True) # e.g., "memory_processor"
    error_message = Column(String)
    raw_input = Column(JSON)
    timestamp = Column(DateTime, default=datetime.utcnow)
