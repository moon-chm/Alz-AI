import os
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query, Form
from typing import Optional
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.patient import Patient, CaretakerPatient
from app.models.alert import Alert
from app.models.medication import Medication
from app.models.appointment import Appointment, AppointmentStatus
from app.models.photo import Photo
from app.models.vitals import Vitals
from app.schemas.caretaker import CaretakerDashboard, PatientStatusResponse, GeofenceSet, VitalsResponse, VitalsCreate, PhotoResponse, AppointmentCreate, AppointmentResponse, WellnessInsightsResponse
from app.schemas.medication import MedicationCreate, MedicationUpdate, MedicationResponse
from app.utils.jwt import get_current_user
from app.core.access_control import require_caretaker
from app.services import memory_service, cloudinary_service, pdf_service, alert_service, insights_service
from app.services.teleconsult_service import teleconsult_provider
from app.utils.geofence_utils import is_point_in_polygon
import redis
import json
from datetime import datetime
import uuid
import tempfile
from app.config import settings
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
try:
    r = redis.from_url(settings.redis_url, decode_responses=True)
except:
    r = None

@router.get("/dashboard", response_model=CaretakerDashboard)
async def get_dashboard(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link:
        return {
            "patient_status": "none",
            "patient_name": "No Active Patient",
            "patient_id": "",
            "recent_alerts": [],
            "medication_compliance_today": 0.0,
            "last_saathi_time": datetime.utcnow(),
            "last_vitals_time": datetime.utcnow()
        }
    
    patient = link.patient
    alerts = db.query(Alert).filter(Alert.patient_id == patient.id, Alert.is_acknowledged == False).order_by(Alert.severity.desc(), Alert.created_at.desc()).limit(10).all()
    
    last_mood_node = memory_service.get_last_mood(str(patient.id))
    mood = last_mood_node.get("mood", "neutral") if last_mood_node else "neutral"
    
    status = "green"
    if any(a.severity >= 4 for a in alerts):
        status = "red"
    elif mood in ["agitated"]:
        status = "red"
    elif mood in ["confused"] or any(a.severity == 3 for a in alerts):
        status = "amber"
        
    # Real-time pulse recovery
    saathi_time = datetime.utcnow()
    vitals_time = datetime.utcnow()
    
    if r:
        vitals_raw = r.get(f"vitals:{patient.id}")
        if vitals_raw:
            v_data = json.loads(vitals_raw)
            vitals_time = datetime.fromisoformat(v_data["recorded_at"])
        
        saathi_raw = r.get(f"saathi:last_res:{patient.id}")
        # If we have a last response, we can use its timestamp if we stored one, 
        # for now we'll just show current if active.

    return CaretakerDashboard(
        patient_status=status,
        patient_name=patient.full_name,
        patient_id=str(patient.id),
        recent_alerts=[{"id": str(a.id), "message": a.message, "severity": a.severity, "created_at": a.created_at.isoformat()} for a in alerts],
        medication_compliance_today=85.5, # Mock for now
        last_saathi_time=saathi_time,
        last_vitals_time=vitals_time,
        primary_doctor_id=patient.doctor_id,
        primary_doctor_name=patient.doctor.full_name if patient.doctor else "Primary Physician"
    )

@router.get("/patient/status", response_model=PatientStatusResponse)
async def get_patient_status(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link:
        raise HTTPException(404, "No patient linked")
        
    last_mood_node = memory_service.get_last_mood(str(link.patient_id))
    mood = last_mood_node.get("mood", "neutral") if last_mood_node else "neutral"
    
    alerts = db.query(Alert).filter(Alert.patient_id == link.patient_id, Alert.is_acknowledged == False).all()
    
    status = "green"
    reason = "All systems normal"
    
    if any(a.severity >= 4 for a in alerts):
        status = "red"
        reason = "Critical alert pending"
    elif mood in ["agitated"]:
        status = "red"
        reason = "Patient is agitated"
    elif mood in ["confused"]:
        status = "amber"
        reason = "Patient is confused"
    elif len(alerts) > 0:
        status = "amber"
        reason = f"{len(alerts)} pending alerts"
        
    return PatientStatusResponse(
        status=status,
        reason=reason,
        updated_at=datetime.utcnow()
    )

@router.post("/geofence/set")
async def set_geofence(data: GeofenceSet, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link:
        raise HTTPException(404, "No patient linked")
        
    if r:
        key = f"geofence:{link.patient_id}"
        r.set(key, json.dumps(data.coordinates))
        
    return {"status": "success", "message": "Geofence updated"}

@router.post("/vitals")
async def record_vitals(data: VitalsCreate, db: Session = Depends(get_db)):
    # Authenticate/Check permission (In production, ensure requester is authorized for patient_id)
    # For now, we trust the background service token
    
    new_vitals = Vitals(
        patient_id=data.patient_id,
        hr=data.hr,
        spo2=data.spo2,
        steps=data.steps,
        sleep=data.sleep,
        hrv=data.hrv,
        recorded_at=data.recorded_at or datetime.utcnow()
    )
    db.add(new_vitals)
    db.commit()
    db.refresh(new_vitals)

    # Update Redis for real-time dashboard
    if r:
        redis_data = {
            "hr": data.hr,
            "spo2": data.spo2,
            "steps": data.steps,
            "sleep": data.sleep,
            "hrv": data.hrv,
            "recorded_at": new_vitals.recorded_at.isoformat()
        }
        r.set(f"vitals:{data.patient_id}", json.dumps(redis_data), ex=600) # 10 min TTL

    # Broadcast update to websocket
    await alert_service.publish_to_websocket(str(data.patient_id), {
        "event_type": "vitals_updated",
        **(redis_data if r else {
            "hr": data.hr,
            "spo2": data.spo2,
            "recorded_at": new_vitals.recorded_at.isoformat()
        })
    })

    return {"status": "success", "id": str(new_vitals.id)}

@router.get("/vitals", response_model=VitalsResponse)
async def get_vitals(
    patient_id: uuid.UUID = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Fallback: query param or current user's link
    if not patient_id:
        link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
        if not link:
            raise HTTPException(404, "No linked patient found")
        patient_id = link.patient_id
    
    p_id_str = str(patient_id)
    
    # 1. Try Redis
    if r:
        raw = r.get(f"vitals:{p_id_str}")
        if raw:
            data = json.loads(raw)
            return VitalsResponse(**data)
            
    # 2. Fallback to Postgres
    latest = db.query(Vitals).filter(Vitals.patient_id == patient_id).order_by(Vitals.recorded_at.desc()).first()
    if not latest:
        return VitalsResponse(
            hr=0, spo2=0, steps=0, sleep=0, recorded_at=datetime.utcnow()
        )

    return VitalsResponse(
        hr=latest.hr,
        spo2=latest.spo2,
        steps=latest.steps,
        sleep=latest.sleep,
        hrv=latest.hrv,
        recorded_at=latest.recorded_at
    )

@router.get("/contacts")
async def get_contacts(
    patient_id: uuid.UUID = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Fallback to query param
    if not patient_id:
        if current_user.role == "patient":
            # Finding patient ID from link if not provided
            link = db.query(CaretakerPatient).filter(CaretakerPatient.patient_id == current_user.id).first()
            if link: patient_id = link.patient_id
            
    if not patient_id:
         raise HTTPException(400, "patient_id required")

    links = db.query(CaretakerPatient).filter(
        CaretakerPatient.patient_id == patient_id,
        CaretakerPatient.link_status == "active"
    ).all()
    
    contacts = []
    for link in links:
        caretaker = db.query(User).filter(User.id == link.caretaker_id).first()
        if caretaker:
            contacts.append({
                "id": str(caretaker.id),
                "name": caretaker.full_name or "Caretaker",
                "relationship": link.relationship or "Primary",
                "phone": caretaker.phone or "",
                "is_primary": link.is_primary or False
            })
    return contacts

@router.get("/location")
async def get_location(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link:
        raise HTTPException(404, "No patient linked")
    
    # Try fetching from Redis first (patient:loc: key used by patient pulse)
    location_data = None
    if r:
        raw = r.get(f"patient:loc:{link.patient_id}")
        if raw:
            location_data = json.loads(raw)
            # Re-verify geofence status in case fence changed since last update
            geofence_raw = r.get(f"geofence:{link.patient_id}")
            if geofence_raw:
                polygon = json.loads(geofence_raw)
                is_safe = is_point_in_polygon(location_data["lat"], location_data["lng"], polygon)
                location_data["geofence_status"] = "inside" if is_safe else "outside"
                location_data["status"] = location_data["geofence_status"]
            else:
                location_data["geofence_status"] = "safe"
    
    if not location_data:
        # Fallback to last known position from Postgres history
        from app.models.location import LocationLog
        latest = db.query(LocationLog).filter(LocationLog.patient_id == link.patient_id).order_by(LocationLog.timestamp.desc()).first()
        if latest:
            # Check geofence for historical fallback too
            geofence_status = "safe"
            if r:
                geofence_raw = r.get(f"geofence:{link.patient_id}")
                if geofence_raw:
                    polygon = json.loads(geofence_raw)
                    geofence_status = "inside" if is_point_in_polygon(latest.latitude, latest.longitude, polygon) else "outside"

            location_data = {
                "lat": latest.latitude,
                "lng": latest.longitude,
                "accuracy": latest.accuracy,
                "status": geofence_status,
                "geofence_status": geofence_status,
                "timestamp": latest.timestamp.isoformat()
            }
        else:
            # Final fallback to realistic static for dev
            location_data = {
                "lat": 28.6139, 
                "lng": 77.2090, 
                "status": "waiting",
                "geofence_status": "waiting",
                "timestamp": datetime.utcnow().isoformat()
            }
    
    # Broadcast update to other listeners
    await alert_service.publish_to_websocket(str(link.patient_id), {
        "event_type": "location_updated",
        **location_data
    })

    return location_data

@router.get("/alerts")
async def get_active_alerts(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link:
        return []
    
    alerts = db.query(Alert).filter(
        Alert.patient_id == link.patient_id, 
        Alert.is_acknowledged == False
    ).order_by(Alert.severity.desc(), Alert.created_at.desc()).all()
    
    return alerts

@router.get("/medications", response_model=list[MedicationResponse])
async def get_medications(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link: return []
    
    meds = db.query(Medication).filter(Medication.patient_id == link.patient_id).all()
    return meds

@router.post("/medications", response_model=MedicationResponse)
async def create_medication(data: MedicationCreate, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    med = Medication(
        patient_id=data.patient_id,
        name=data.name,
        dosage=data.dosage,
        scheduled_times=data.scheduled_times, # stored as json
        tablet_photo_url=data.tablet_photo_url,
        created_by=current_user.id
    )
    db.add(med)
    db.commit()
    db.refresh(med)
    return med

@router.put("/medications/{medication_id}", response_model=MedicationResponse)
async def update_medication(medication_id: uuid.UUID, data: MedicationUpdate, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    med = db.query(Medication).filter(Medication.id == medication_id).first()
    if not med: raise HTTPException(404, "Medication not found")
    
    if data.name is not None: med.name = data.name
    if data.dosage is not None: med.dosage = data.dosage
    if data.scheduled_times is not None: med.scheduled_times = data.scheduled_times
    if data.tablet_photo_url is not None: med.tablet_photo_url = data.tablet_photo_url
    if data.is_active is not None: med.is_active = data.is_active
    
    db.commit()
    db.refresh(med)
    return med

@router.delete("/medications/{medication_id}")
async def delete_medication(medication_id: uuid.UUID, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    med = db.query(Medication).filter(Medication.id == medication_id).first()
    if not med: raise HTTPException(404, "Medication not found")
    
    med.is_active = False # soft delete
    db.commit()
    return {"status": "success"}

@router.post("/photo/send")
async def send_photo(
    patient_id: Optional[uuid.UUID] = Query(None), 
    caption: Optional[str] = Form(None), 
    file: UploadFile = File(...), 
    current_user: User = Depends(require_caretaker), 
    db: Session = Depends(get_db)
):
    if not patient_id:
        link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
        if not link:
            raise HTTPException(404, "No patient linked to send photo for")
        patient_id = link.patient_id

    # Save to temp file
    temp_path = None
    try:
        ext = os.path.splitext(file.filename)[1] or ".jpg"
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_path = temp_file.name
        
        # Real Cloudinary or Mock fallback
        try:
            cloudinary_url = await cloudinary_service.upload_file(temp_path, folder=f"patient-photos/{patient_id}")
        except Exception as e:
            # Fallback for dev environments without Cloudinary env vars
            logger.error(f"Cloudinary Upload Failed: {e}")
            cloudinary_url = f"https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg" 

        # Save to DB
        new_photo = Photo(
            patient_id=patient_id,
            sender_id=current_user.id,
            cloudinary_url=cloudinary_url,
            caption=caption
        )
        db.add(new_photo)
        db.commit()
        db.refresh(new_photo)
        
        return {"status": "success", "id": str(new_photo.id), "url": cloudinary_url}
    
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@router.get("/photos", response_model=list[PhotoResponse])
async def get_photos(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link:
        return []
        
    photos = db.query(Photo).filter(Photo.patient_id == link.patient_id).order_by(Photo.sent_at.desc()).all()
    
    # Enrich with sender name and relationship
    results = []
    for p in photos:
        # Fetch relationship between sender and patient
        rel_link = db.query(CaretakerPatient).filter(
            CaretakerPatient.caretaker_id == p.sender_id,
            CaretakerPatient.patient_id == p.patient_id
        ).first()
        relationship = rel_link.relationship if rel_link else "Family Member"

        p_dict = {
            "id": p.id,
            "cloudinary_url": p.cloudinary_url,
            "caption": p.caption,
            "sender_name": p.sender.full_name if p.sender else "Caretaker",
            "relationship": relationship,
            "sent_at": p.sent_at
        }
        results.append(p_dict)
        
    return results

@router.delete("/photo/{photo_id}")
async def delete_photo(photo_id: str, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not photo:
        raise HTTPException(404, "Photo not found")
        
    # Security check: Ensure the photo belongs to a patient this caretaker manages
    link = db.query(CaretakerPatient).filter(
        CaretakerPatient.caretaker_id == current_user.id,
        CaretakerPatient.patient_id == photo.patient_id
    ).first()
    
    if not link:
        raise HTTPException(403, "Not authorized to delete this photo")
        
    # Extricate public_id and delete from Cloudinary Bucket securely
    if photo.cloudinary_url:
        try:
            parts = photo.cloudinary_url.split('/upload/')
            if len(parts) == 2:
                path_part = parts[1]
                # Remove API version prefix if present (e.g., v1776629428/)
                if path_part.startswith('v') and '/' in path_part:
                    path_part = path_part.split('/', 1)[1]
                # Remove file extension
                public_id = path_part.rsplit('.', 1)[0]
                
                # Delete from Cloud
                await cloudinary_service.delete_file(public_id)
        except Exception as e:
            logger.error(f"Failed to delete Cloudinary asset {photo.cloudinary_url}: {e}")

    db.delete(photo)
    db.commit()
    return {"status": "success"}

@router.post("/memory")
async def create_memory(data: dict, current_user: User = Depends(require_caretaker)):
    return memory_service.create_memory_node(data["patient_id"], data["content"], data["category"], str(current_user.id))

@router.get("/memory")
async def get_memories(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link: return []
    return memory_service.get_memories(str(link.patient_id))

@router.put("/memory/{memory_id}")
async def update_memory(memory_id: str, data: dict, current_user: User = Depends(require_caretaker)):
    memory_service.update_memory_node(memory_id, data.get("content"), data.get("category"))
    return {"status": "success"}

@router.delete("/memory/{memory_id}")
async def delete_memory(memory_id: str, current_user: User = Depends(require_caretaker)):
    memory_service.delete_memory_node(memory_id)
    return {"status": "success"}

@router.get("/appointments", response_model=list[AppointmentResponse])
async def get_appointments(current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link: return []
    
    appointments = db.query(Appointment).filter(Appointment.patient_id == link.patient_id).order_by(Appointment.scheduled_at.asc()).all()
    
    results = []
    for appt in appointments:
        results.append({
            "id": appt.id,
            "patient_id": appt.patient_id,
            "doctor_id": appt.doctor_id,
            "scheduled_at": appt.scheduled_at,
            "status": appt.status.value,
            "notes": appt.notes,
            "doctor_name": appt.doctor.full_name if appt.doctor else "Doctor"
        })
    return results

@router.post("/appointments", response_model=AppointmentResponse)
async def create_appointment(data: AppointmentCreate, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    # Task List:
    # - [x] Stabilize Login Page Redirect Loop
    # - [x] Harden Teleconsultation Link Generation (Backend)
    # - [x] Implement robust room naming in TeleconsultService (Backend)
    # - [ ] Verify Jitsi connectivity with new URL pattern
    
    appt = Appointment(
        patient_id=data.patient_id,
        doctor_id=data.doctor_id,
        caretaker_id=current_user.id,
        scheduled_at=data.scheduled_at,
        notes=data.notes,
        status=AppointmentStatus.pending
    )
    
    # Generate Teleconsultation Link (Mandatory for Virtual Care)
    appt.meeting_url = teleconsult_provider.create_meeting(str(appt.id), str(appt.patient_id))
    
    db.add(appt)
    db.commit()
    db.refresh(appt)
    
    return {
        "id": appt.id,
        "patient_id": appt.patient_id,
        "doctor_id": appt.doctor_id,
        "scheduled_at": appt.scheduled_at,
        "status": appt.status.value,
        "notes": appt.notes,
        "meeting_url": appt.meeting_url,
        "doctor_name": appt.doctor.full_name if appt.doctor else "Doctor"
    }

@router.post("/reports/pdf")
async def generate_report(data: dict, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    from fastapi.responses import FileResponse
    import os
    
    link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
    if not link:
        raise HTTPException(404, "No patient linked to generate report")
    
    period = data.get("period_days", 30)
    temp_path = await pdf_service.generate_patient_report(str(link.patient_id), period)
    
    filename = f"AlzAI_Report_{period}days.pdf"
    return FileResponse(
        path=temp_path,
        media_type="application/pdf",
        filename=filename,
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.post("/link-patient")
async def link_patient(data: dict, current_user: User = Depends(require_caretaker), db: Session = Depends(get_db)):
    p_id = data.get("patient_unique_id")
    if not p_id: raise HTTPException(400, "Patient Unique ID is required")
    
    patient = db.query(Patient).filter(Patient.patient_unique_id == p_id.strip()).first()
    if not patient: raise HTTPException(404, "Patient not found")
    
    # Check if already linked
    existing = db.query(CaretakerPatient).filter(
        CaretakerPatient.caretaker_id == current_user.id,
        CaretakerPatient.patient_id == patient.id
    ).first()
    if existing: return {"status": "success", "message": "Already linked", "patient_id": str(patient.id)}
    
    # Create link
    new_link = CaretakerPatient(
        caretaker_id=current_user.id, 
        patient_id=patient.id,
        relationship="primary"
    )
    db.add(new_link)
    db.commit()
    
    return {"status": "success", "message": "Patient linked successfully", "patient_id": str(patient.id), "patient_name": patient.full_name}
