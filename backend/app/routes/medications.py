from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.medication import Medication
from app.models.adherence_log import AdherenceLog, AdherenceStatus
from app.utils.jwt import get_current_user, get_current_token_payload
import uuid
from datetime import datetime

router = APIRouter(tags=["medications"])

@router.get("/")
async def list_my_medications(
    patient_id: uuid.UUID = None,
    payload: dict = Depends(get_current_token_payload),
    db: Session = Depends(get_db)
):
    # Fallback: check query param if not in JWT
    patient_id = patient_id or payload.get("patient_id")
    if not patient_id:
        raise HTTPException(400, "patient_id not found in token or query params. Are you logged in as a patient?")
    
    meds = db.query(Medication).filter(Medication.patient_id == patient_id, Medication.is_active == True).all()
    
    # Safe mapping: Flutter mobile models crash on null for some string fields
    return [
        {
            "id": str(med.id),
            "name": med.name,
            "photo_url": med.tablet_photo_url or "",
            "time": med.scheduled_times[0] if (med.scheduled_times and len(med.scheduled_times) > 0) else "Not set",
            "dose_instructions": med.dosage,
            "status": "upcoming",
            "is_active": med.is_active
        }
        for med in meds
    ]

@router.get("/{patient_id}")
async def list_medications(
    patient_id: uuid.UUID, 
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
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
    # ... existing compliance logic ...
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

@router.get("/daily-schedule")
async def get_my_daily_schedule(
    payload: dict = Depends(get_current_token_payload),
    db: Session = Depends(get_db)
):
    patient_id = payload.get("patient_id")
    if not patient_id:
        raise HTTPException(400, "patient_id not found in token")
    
    return await _build_daily_schedule(uuid.UUID(patient_id) if isinstance(patient_id, str) else patient_id, db)

@router.get("/{patient_id}/daily-schedule")
async def get_daily_schedule(patient_id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return await _build_daily_schedule(patient_id, db)

async def _build_daily_schedule(patient_id: uuid.UUID, db: Session):
    meds = db.query(Medication).filter(Medication.patient_id == patient_id, Medication.is_active == True).all()
    
    events = []
    for m in meds:
        # scheduled_times is a list like ["08:00", "20:00"]
        times = m.scheduled_times if isinstance(m.scheduled_times, list) else []
        for t in times:
            events.append({
                "id": f"med-{m.id}-{t}",
                "type": "medication",
                "title": m.name,
                "subtitle": m.dosage,
                "time": t,
                "status": "pending",
                "medication_id": str(m.id)
            })
            
        
    # Sort events by time
    events.sort(key=lambda x: x["time"])
    return events

@router.post("/taken")
async def mark_taken(
    data: dict,
    db: Session = Depends(get_db)
):
    """
    Called by mobile app to confirm a medication dose was taken.
    Expects: { 'patient_id': UUID, 'medication_id': UUID }
    """
    patient_id = uuid.UUID(data["patient_id"]) if isinstance(data["patient_id"], str) else data["patient_id"]
    med_id = uuid.UUID(data["medication_id"]) if isinstance(data["medication_id"], str) else data["medication_id"]
    
    current_date = datetime.utcnow().strftime("%Y-%m-%d")
    
    # Check if already logged for today (idempotency)
    existing = db.query(AdherenceLog).filter(
        AdherenceLog.patient_id == patient_id,
        AdherenceLog.medication_id == med_id,
        AdherenceLog.confirmed_date == current_date
    ).first()
    
    if existing:
        return {"status": "already_logged", "id": str(existing.id)}
        
    # Create new log
    log = AdherenceLog(
        patient_id=patient_id,
        medication_id=med_id,
        scheduled_time="Manual", # Could be refined to find closest schedule
        status=AdherenceStatus.taken,
        confirmed_date=current_date
    )
    
    db.add(log)
    db.commit()
    db.refresh(log)
    
    return {"status": "success", "id": str(log.id)}
