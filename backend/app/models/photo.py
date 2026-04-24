import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.postgres import Base

class Photo(Base):
    __tablename__ = "photos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    sender_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    cloudinary_url = Column(String, nullable=False)
    caption = Column(String, nullable=True)
    memory_prompt = Column(String, nullable=True) # "Remember the trip to Konkan?"
    people_involved = Column(String, nullable=True) # "Arjun, Sunita"
    importance_score = Column(Integer, default=3) # 1-5 (5=Core Memory)
    sent_at = Column(DateTime, default=datetime.utcnow)
    is_viewed = Column(Boolean, default=False)

    # Relationships
    patient = relationship("Patient", back_populates="photos", foreign_keys=[patient_id])
    sender = relationship("User", foreign_keys=[sender_id])
