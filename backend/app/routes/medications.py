from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.medication import Medication
from app.utils.jwt import get_current_user
import uuid
from datetime import datetime, timedelta
import random

router = APIRouter(tags=["medications"])

@router.get("/{patient_id}")
async def list_medications(patient_id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Medication).filter(Medication.patient_id == patient_id, Medication.is_active == True).all()

@router.post("/")
async def create_medication(data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    med = Medication(
        patient_id=data["patient_id"],
        name=data["name"],
        dosage=data["dosage"],
        scheduled_times=data["scheduled_times"],
        tablet_photo_url=data.get("tablet_photo_url"),
        created_by=current_user.id
    )
    db.add(med)
    db.commit()
    db.refresh(med)
    return med

@router.put("/{id}")
async def update_medication(id: uuid.UUID, data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    med = db.query(Medication).filter(Medication.id == id).first()
    if not med: raise HTTPException(404, "Medication not found")
    
    if "name" in data: med.name = data["name"]
    if "dosage" in data: med.dosage = data["dosage"]
    if "scheduled_times" in data: med.scheduled_times = data["scheduled_times"]
    if "tablet_photo_url" in data: med.tablet_photo_url = data["tablet_photo_url"]
    
    db.commit()
    db.refresh(med)
    return med

@router.delete("/{id}")
async def delete_medication(id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    med = db.query(Medication).filter(Medication.id == id).first()
    if not med: raise HTTPException(404, "Medication not found")
    
    med.is_active = False
    db.commit()
    return {"status": "deleted"}

@router.get("/{patient_id}/compliance")
async def get_compliance(patient_id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Mocking compliance 7-day grid
    meds = db.query(Medication).filter(Medication.patient_id == patient_id, Medication.is_active == True).all()
    base = datetime.utcnow()
    dates = [(base - timedelta(days=x)).strftime("%Y-%m-%d") for x in range(6, -1, -1)]
    
    result = []
    for m in meds:
        days = []
        for d in dates:
            days.append({
                "date": d,
                "taken": random.choice([True, True, True, False]),
                "scheduled": True
            })
        result.append({
            "medication_name": m.name,
            "days": days
        })
    return result
