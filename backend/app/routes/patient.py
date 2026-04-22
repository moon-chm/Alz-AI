from fastapi import APIRouter, Depends, HTTPException
from typing import Optional
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.patient import Patient, CaretakerPatient
from app.models.photo import Photo
from app.utils.jwt import get_current_user, get_current_token_payload
from app.models.user import User
from app.models.location import LocationLog
from app.services import alert_service, memory_service
from app.database.redis_client import redis_client
from app.utils.geofence_utils import is_point_in_polygon
import uuid
import json
from datetime import datetime

router = APIRouter(tags=["patient"])

@router.get("/profile")
async def patient_profile(patient_id: Optional[uuid.UUID] = None, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not patient_id:
        link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
        if not link: raise HTTPException(404, "No patient linked to this user")
        patient_id = link.patient_id
        
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient: raise HTTPException(404, "Patient not found")
    return patient

@router.get("/photos")
async def patient_photos(patient_id: Optional[uuid.UUID] = None, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not patient_id:
        link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
        if not link: return []
        patient_id = link.patient_id
        
    photos = db.query(Photo).filter(Photo.patient_id == patient_id).order_by(Photo.sent_at.desc()).limit(20).all()
    return photos

@router.post("/medication/confirm")
async def confirm_medication(data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    patient_id = data.get("patient_id")
    if not patient_id:
        link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
        if not link: raise HTTPException(404, "No patient linked to confirm medication")
        patient_id = link.patient_id
        
    # data: patient_id, medication_id
    # Would create audit log here
    return {"status": "confirmed", "medication_id": data.get("medication_id"), "patient_id": str(patient_id)}

@router.post("/sos")
async def trigger_sos(data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    patient_id = data.get("patient_id")
    if not patient_id:
        link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
        if not link: raise HTTPException(404, "No patient linked to trigger SOS")
        patient_id = link.patient_id

    # Use alert_service to create P5 alert
    alert = await alert_service.create_alert(
        db=db,
        patient_id=patient_id,
        alert_type="sos",
        severity=5,
        message="Patient triggered SOS alert via app",
        extra_data={"lat": data.get("lat"), "lng": data.get("lng")}
    )
    return {"status": "sos_triggered", "alert_id": str(alert.id), "patient_id": str(patient_id)}

@router.get("/family")
async def get_family(patient_id: Optional[str] = None, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not patient_id:
        link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
        if not link: return []
        patient_id = str(link.patient_id)
    return memory_service.get_family(patient_id)

@router.get("/geofence")
async def get_geofence(
    payload: dict = Depends(get_current_token_payload)
):
    """
    Retrieves the geofence boundaries for the current patient.
    Used by the mobile app to perform local geofence monitoring.
    """
    patient_id = payload.get("patient_id")
    if not patient_id:
        raise HTTPException(400, "patient_id missing in token")
        
    if redis_client:
        geofence_raw = redis_client.get(f"geofence:{patient_id}")
        if geofence_raw:
            return {"status": "success", "coordinates": json.loads(geofence_raw)}
            
    return {"status": "success", "coordinates": []}

@router.post("/location")
async def update_location(
    data: dict, 
    payload: dict = Depends(get_current_token_payload),
    db: Session = Depends(get_db)
):
    """
    Receives periodic location updates from the mobile background service.
    Updates Redis for real-time dashboard and Postgres for history.
    """
    patient_id = payload.get("patient_id")
    if not patient_id:
        # Fallback for testing/unauthenticated debug
        patient_id = data.get("patient_id")
        if not patient_id:
            raise HTTPException(400, "patient_id missing")

    lat = data.get("lat")
    lng = data.get("lng")
    accuracy = data.get("accuracy", 0.0)
    
    if lat is None or lng is None:
        raise HTTPException(400, "latitude and longitude required")

    # 1. Save to Postgres (History)
    loc_log = LocationLog(
        patient_id=patient_id,
        latitude=lat,
        longitude=lng,
        accuracy=accuracy,
        provider=data.get("provider", "fused")
    )
    db.add(loc_log)
    db.commit()

    # 2. Update Redis (Real-time Pulse)
    status = "safe"
    if redis_client:
        # Check Geofence
        geofence_raw = redis_client.get(f"geofence:{patient_id}")
        if geofence_raw:
            polygon = json.loads(geofence_raw)
            if not is_point_in_polygon(lat, lng, polygon):
                status = "outside"
                # Trigger critical alert if outside (service handles dedup)
                await alert_service.create_alert(
                    db=db,
                    patient_id=patient_id,
                    alert_type="wandering",
                    severity=4,
                    message="Patient has left the safe zone!",
                    extra_data={"lat": lat, "lng": lng}
                )
            else:
                status = "inside"

        loc_data = {
            "lat": lat,
            "lng": lng,
            "accuracy": accuracy,
            "timestamp": datetime.utcnow().isoformat(),
            "status": status,
            "geofence_status": status
        }
        redis_client.set(f"patient:loc:{patient_id}", json.dumps(loc_data), ex=1800) # 30 min TTL

    # 3. Broadcast to WebSockets
    await alert_service.publish_to_websocket(patient_id, {
        "event_type": "location_update",
        "data": {
            "latitude": lat,
            "longitude": lng,
            "accuracy": accuracy,
            "geofence_status": status
        }
    })

    return {"status": "success", "patient_id": str(patient_id)}
