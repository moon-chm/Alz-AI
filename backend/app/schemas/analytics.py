from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID

class AdherenceDay(BaseModel):
    date: str
    scheduled: int
    taken: int
    adherence: Optional[float] = None

class AdherenceSummary(BaseModel):
    average_7d: float
    average_30d: float

class AdherenceTrendResponse(BaseModel):
    patient_id: UUID
    range: str
    data: List[AdherenceDay]
    summary: AdherenceSummary
