from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID

class AlertCreate(BaseModel):
    patient_id: UUID
    alert_type: str
    severity: int = Field(ge=1, le=5)
    message: str

class AlertResponse(BaseModel):
    id: UUID
    patient_id: UUID
    alert_type: str
    severity: int
    message: str
    is_acknowledged: bool
    acknowledged_by: Optional[UUID] = None
    acknowledged_at: Optional[datetime] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

class AlertAcknowledge(BaseModel):
    alert_id: UUID

class AlertHistory(BaseModel):
    alerts: List[AlertResponse]
    total: int
    page: int
    limit: int
