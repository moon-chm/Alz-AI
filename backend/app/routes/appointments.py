from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.appointment import Appointment, AppointmentStatus, TeleconsultMode
from app.models.user import User, RoleEnum
from app.models.patient import Patient, CaretakerPatient
from app.services.teleconsult_service import jitsi_provider
from app.utils.jwt import get_current_user
from datetime import datetime, timedelta
import uuid
import json
import redis.asyncio as aioredis
from app.config import settings

router = APIRouter(tags=["appointments"])

@router.get("/")
async def list_appointments(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    query = db.query(Appointment)
    if current_user.role == RoleEnum.doctor:
        query = query.filter(Appointment.doctor_id == current_user.id)
    elif current_user.role == RoleEnum.caretaker:
        links = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).all()
        p_ids = [l.patient_id for l in links]
        query = query.filter(Appointment.patient_id.in_(p_ids))
        
    appointments = query.order_by(Appointment.scheduled_at.asc()).all()
    
    result = []
    for app in appointments:
        patient = db.query(Patient).filter(Patient.id == app.patient_id).first()
        caretaker = db.query(User).filter(User.id == app.caretaker_id).first() if app.caretaker_id else None
        
        app_data = {
            "id": app.id,
            "patient_id": app.patient_id,
            "patient_name": patient.full_name if patient else "Unknown",
            "caretaker_id": app.caretaker_id,
            "caretaker_name": caretaker.full_name if caretaker else "None",
            "doctor_id": app.doctor_id,
            "scheduled_at": app.scheduled_at,
            "status": app.status,
            "notes": app.notes,
            "mode": app.mode,
            "meeting_url": app.meeting_url
        }
        result.append(app_data)
        
    return result

@router.post("/")
async def create_appointment(data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    mode = data.get("mode", TeleconsultMode.in_person)
    meeting_url = None
    
    if mode == TeleconsultMode.teleconsult:
        # Generate deterministic meeting link
        # Format: alzai-{patient_unique_id}-{timestamp}
        patient = db.query(Patient).filter(Patient.id == data["patient_id"]).first()
        meeting_url = jitsi_provider.generate_meeting_link(
            appointment_id=str(uuid.uuid4())[:8], # Sub-ID for room uniqueness
            patient_id=patient.patient_unique_id if patient else str(data["patient_id"])
        )

    app = Appointment(
        patient_id=data["patient_id"],
        doctor_id=data["doctor_id"],
        caretaker_id=data.get("caretaker_id"),
        scheduled_at=data["scheduled_at"],
        notes=data.get("notes", ""),
        mode=mode,
        meeting_url=meeting_url
    )
    db.add(app)
    db.commit()
    db.refresh(app)
    return app

@router.put("/{id}")
async def update_appointment(id: uuid.UUID, data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    app = db.query(Appointment).filter(Appointment.id == id).first()
    if not app: raise HTTPException(404, "Appointment not found")
    
    if "status" in data: app.status = data["status"]
    if "notes" in data: app.notes = data["notes"]
    
    db.commit()
    db.refresh(app)
    return app

@router.delete("/{id}")
async def cancel_appointment(id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    app = db.query(Appointment).filter(Appointment.id == id).first()
    if not app: raise HTTPException(404, "Appointment not found")
    
    app.status = AppointmentStatus.cancelled
    db.commit()
    return {"status": "cancelled"}

@router.post("/{id}/init-teleconsult")
async def init_teleconsult(id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role != RoleEnum.doctor:
        raise HTTPException(403, "Only doctors can initialize teleconsults")
        
    app = db.query(Appointment).filter(Appointment.id == id, Appointment.doctor_id == current_user.id).first()
    if not app: raise HTTPException(404, "Appointment not found")
    
    if not app.meeting_url:
        app.meeting_url = f"https://meet.jit.si/alz-ai-{str(app.id)[:8]}"
        db.commit()
        db.refresh(app)
        
    # Notify caretaker via Redis pub/sub
    try:
        r = aioredis.from_url(settings.redis_url)
        channel = f"patient:{app.patient_id}:events"
        message = json.dumps({
            "type": "TELECONSULT_READY",
            "appointment_id": str(app.id),
            "link": app.meeting_url,
            "doctor_name": current_user.full_name
        })
        await r.publish(channel, message)
        await r.aclose()
    except Exception as e:
        print(f"Error publishing to Redis: {e}")
        
    return {"status": "teleconsult_initialized", "url": app.meeting_url}

@router.get("/upcoming")
async def upcoming_appointments(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    now = datetime.utcnow()
    next_week = now + timedelta(days=7)
    
    query = db.query(Appointment).filter(Appointment.scheduled_at >= now, Appointment.scheduled_at <= next_week)
    
    if current_user.role == RoleEnum.doctor:
        query = query.filter(Appointment.doctor_id == current_user.id)
    elif current_user.role == RoleEnum.caretaker:
        links = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).all()
        p_ids = [l.patient_id for l in links]
        query = query.filter(Appointment.patient_id.in_(p_ids))
        
    appointments = query.order_by(Appointment.scheduled_at.asc()).all()
    
    result = []
    for app in appointments:
        patient = db.query(Patient).filter(Patient.id == app.patient_id).first()
        caretaker = db.query(User).filter(User.id == app.caretaker_id).first() if app.caretaker_id else None
        
        app_data = {
            "id": app.id,
            "patient_id": app.patient_id,
            "patient_name": patient.full_name if patient else "Unknown",
            "caretaker_id": app.caretaker_id,
            "caretaker_name": caretaker.full_name if caretaker else "None",
            "doctor_id": app.doctor_id,
            "scheduled_at": app.scheduled_at,
            "status": app.status,
            "notes": app.notes
        }
        result.append(app_data)
        
    return result
