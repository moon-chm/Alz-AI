from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from uuid import UUID

class GeofenceCoordinates(BaseModel):
    lat: float
    lng: float

class GeofenceZoneCreate(BaseModel):
    patient_id: UUID
    name: str
    zone_type: str # safe, buffer, danger
    coordinates: List[GeofenceCoordinates]
    priority: Optional[int] = 1

class GeofenceZoneUpdate(BaseModel):
    name: Optional[str] = None
    zone_type: Optional[str] = None # safe, buffer, danger
    coordinates: Optional[List[GeofenceCoordinates]] = None
    priority: Optional[int] = None
    is_active: Optional[bool] = None

class GeofenceZoneResponse(BaseModel):
    id: UUID
    patient_id: UUID
    name: str
    zone_type: str
    coordinates: List[GeofenceCoordinates]
    priority: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class HistoricalLocation(BaseModel):
    lat: float
    lng: float
    timestamp: datetime
    entropy_score: Optional[float] = 0.0

class LocationHistoryResponse(BaseModel):
    patient_id: UUID
    path: List[HistoricalLocation]
    total_points: int

class LocationAnalyticsResponse(BaseModel):
    patient_id: UUID
    wandering_entropy: float # 0-100
    risk_level: str # low, moderate, high
    recent_anomalies: List[dict]
    heatmap_data: List[dict] # {lat, lng, intensity}
    speed_history: List[dict] # {time, speed}
    score_history: List[dict] # {time, score}

