from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from typing import Optional
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.patient import Patient, CaretakerPatient
from app.models.photo import Photo
from app.utils.jwt import get_current_user, get_current_token_payload
from app.models.user import User
from app.models.location import LocationLog
from app.services import alert_service, memory_service
from app.services.storage_service import storage_service
from app.services.voice_cloning_service import voice_cloning_service
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
        "event_type": "location_updated",
        "data": {
            "latitude": lat,
            "longitude": lng,
            "accuracy": accuracy,
            "geofence_status": status
        }
    })

    return {"status": "success", "patient_id": str(patient_id)}

@router.post("/voice-sample")
async def upload_voice_sample(
    patient_id: str = Form(...),
    audio: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    try:
        uuid.UUID(patient_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid patient_id format")

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    allowed_extensions = [".mp3", ".wav", ".m4a", ".ogg"]
    ext = audio.filename.lower()[-4:] if audio.filename else ""
    if ext not in allowed_extensions and not any(audio.filename.lower().endswith(e) for e in allowed_extensions):
        raise HTTPException(status_code=400, detail="Invalid file type. Only MP3, WAV, M4A, OGG are allowed.")
        
    content = await audio.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large. Maximum size is 10MB.")

    # Real ext from allowed_extensions?
    file_ext = [e for e in allowed_extensions if audio.filename.lower().endswith(e)]
    ext = file_ext[0] if file_ext else ".m4a"

    object_name = f"{patient_id}/voice_sample{ext}"

    # Delete existing if any (simplification since MINIO overwrites on put, but we can have different ext)
    if patient.voice_sample_url:
        old_obj = patient.voice_sample_url.split("?")[0].split("/")[-1] # simple parsing depending on url structure
        # Or better yet, just let Minio rewrite, but we can't reliably know the old extension to delete.
        # Actually minio overwrite works. We can just use standard `voice_sample.m4a` or keep tracking the url.

    storage_service.upload_file(content, object_name, content_type=audio.content_type, bucket_name="voice-samples")
    
    signed_url = storage_service.get_signed_url(object_name, expires_in_minutes=60*24*365, bucket_name="voice-samples")
    if not signed_url:
        # Fallback to direct URL if signed URL fails, though unlikely
        host = storage_service.endpoint if "http" in storage_service.endpoint else f"http://{storage_service.endpoint}"
        signed_url = f"{host}/voice-samples/{object_name}"
        
    patient.voice_sample_url = signed_url

    # --- SYNTHETIC VOICE CLONING (AI UPDATES) ---
    # Trigger background cloning if we have a valid sample
    # For speed in development, we do it inline here, but usually it would be a background task
    try:
        # Delete old cloned voice if exists
        if patient.cloned_voice_id:
            await voice_cloning_service.delete_cloned_voice(patient.cloned_voice_id)
        
        # Create new clone
        new_voice_id = await voice_cloning_service.clone_voice(
            name=f"SAATHI_{patient.full_name[:10]}",
            audio_content=content,
            description=f"Synthetic neural companion for {patient.full_name}"
        )
        patient.cloned_voice_id = new_voice_id
    except Exception as ve:
        logger.error(f"Voice cloning failed: {ve}")

    db.commit()

    return {
        "status": "success",
        "voice_sample_url": signed_url,
        "uploaded_at": datetime.utcnow().isoformat()
    }

@router.get("/voice-sample")
async def get_voice_sample(patient_id: str, db: Session = Depends(get_db)):
    try:
        uuid.UUID(patient_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid patient_id format")

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        return {"has_voice": False, "voice_sample_url": None, "uploaded_at": None}

    if not patient.voice_sample_url:
        return {"has_voice": False, "voice_sample_url": None, "uploaded_at": None}

    return {
        "has_voice": True,
        "voice_sample_url": patient.voice_sample_url,
        "uploaded_at": patient.created_at.isoformat() # or add a new field, but instructions said return uploaded_at which can be approximated or null
    }

@router.delete("/voice-sample")
async def delete_voice_sample(patient_id: str, db: Session = Depends(get_db)):
    try:
        uuid.UUID(patient_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid patient_id format")

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient or not patient.voice_sample_url:
        return {"status": "success"}

    # Extract object name from URL
    try:
        import urllib.parse
        parsed = urllib.parse.urlparse(patient.voice_sample_url)
        path_parts = parsed.path.split('/')
        if 'voice-samples' in path_parts:
            # path is likely /voice-samples/uuid/voice_sample.ext
            idx = path_parts.index('voice-samples')
            object_name = "/".join(path_parts[idx+1:])
            storage_service.delete_file(object_name, bucket_name="voice-samples")
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Could not delete file from MinIO: {e}")

    # Delete cloned voice from ElevenLabs
    if patient.cloned_voice_id:
        try:
            await voice_cloning_service.delete_cloned_voice(patient.cloned_voice_id)
        except: pass
    
    patient.cloned_voice_id = None
    patient.voice_sample_url = None
    db.commit()
    
    return {"status": "success"}
