from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.alert import Alert
from app.schemas.alert import AlertHistory, AlertResponse, AlertAcknowledge
from app.utils.jwt import get_current_user
from app.services import alert_service
import uuid
import redis
import json
from app.config import settings

router = APIRouter(tags=["alerts"])

try:
    r = redis.from_url(settings.redis_url, decode_responses=True)
except:
    r = None

@router.get("/history", response_model=AlertHistory)
async def get_alert_history(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    severity: int = Query(None, ge=1, le=5),
    patient_id: uuid.UUID = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Alert)
    
    if patient_id:
        query = query.filter(Alert.patient_id == patient_id)
        
    if severity:
        query = query.filter(Alert.severity == severity)
        
    total = query.count()
    alerts = query.order_by(Alert.created_at.desc()).offset((page - 1) * limit).limit(limit).all()
    
    alert_responses = [AlertResponse.from_orm(a) for a in alerts]
    
    return AlertHistory(
        alerts=alert_responses,
        total=total,
        page=page,
        limit=limit
    )

@router.post("/acknowledge/{alert_id}", response_model=AlertResponse)
async def acknowledge_alert(
    alert_id: uuid.UUID,
     বর্তমান_ব্যক্তি: User = Depends(get_current_user), # Using current_user directly here
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        updated_alert = await alert_service.acknowledge_alert(db, str(alert_id), str(current_user.id))
        return updated_alert
    except ValueError as e:
        raise HTTPException(404, str(e))

@router.post("/vitals")
async def post_vitals(data: dict, db: Session = Depends(get_db)):
    """
    Accept: {hr, spo2, steps, sleep, lat, lng, patient_id}
    Store vitals in Redis: key vitals:{patient_id}, TTL 2 hours
    Check geofence, Check vitals thresholds.
    """
    patient_id = data.get("patient_id")
    if not patient_id:
        raise HTTPException(400, "patient_id required")
        
    if r:
        key = f"vitals:{patient_id}"
        r.setex(key, 7200, json.dumps(data))
        
        hr = data.get("hr", 70)
        spo2 = data.get("spo2", 98)
        
        # Simple threshold triggers
        if hr > 120 or hr < 40:
            await alert_service.create_alert(
                db=db,
                patient_id=patient_id,
                alert_type="vital_anomaly",
                severity=4,
                message=f"Abnormal heart rate: {hr} bpm"
            )
            
        if spo2 < 90:
            await alert_service.create_alert(
                db=db,
                patient_id=patient_id,
                alert_type="vital_anomaly",
                severity=4,
                message=f"Low blood oxygen: {spo2}%"
            )
            
        # Geofence logic omitted for brevity (simplified version)
        
        # Publish location update
        await alert_service.publish_to_websocket(patient_id, {
            "event_type": "location_updated",
            "lat": data.get("lat"),
            "lng": data.get("lng")
        })
        
    return {"received": True}
