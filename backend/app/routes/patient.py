from fastapi import APIRouter, Depends, HTTPException
from typing import Optional
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.patient import Patient, CaretakerPatient
from app.models.photo import Photo
from app.utils.jwt import get_current_user
from app.models.user import User
from app.services import alert_service, memory_service
import uuid

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
