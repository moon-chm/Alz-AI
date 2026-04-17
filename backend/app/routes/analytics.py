from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
import uuid
import random
from datetime import datetime, timedelta

router = APIRouter(tags=["analytics"])

def _generate_mock_dates(days=30):
    base = datetime.utcnow()
    return [(base - timedelta(days=x)).strftime("%Y-%m-%d") for x in range(days-1, -1, -1)]

@router.get("/steps/{patient_id}")
async def get_steps(patient_id: uuid.UUID, db: Session = Depends(get_db)):
    dates = _generate_mock_dates()
    return [{"date": d, "steps": random.randint(1500, 5000)} for d in dates]

@router.get("/heartrate/{patient_id}")
async def get_heartrate(patient_id: uuid.UUID, db: Session = Depends(get_db)):
    dates = _generate_mock_dates()
    return [{
        "date": d,
        "avg_hr": random.randint(65, 85),
        "min_hr": random.randint(55, 65),
        "max_hr": random.randint(90, 110)
    } for d in dates]

@router.get("/sleep/{patient_id}")
async def get_sleep(patient_id: uuid.UUID, db: Session = Depends(get_db)):
    dates = _generate_mock_dates()
    return [{
        "date": d,
        "hours": round(random.uniform(5.5, 8.5), 1),
        "quality": random.randint(60, 95)
    } for d in dates]

@router.get("/medication/{patient_id}")
async def get_medication_compliance(patient_id: uuid.UUID, db: Session = Depends(get_db)):
    dates = _generate_mock_dates(7)
    meds = ["Donepezil", "Memantine", "Vitamin D"]
    
    result = []
    for m in meds:
        days = []
        for d in dates:
            days.append({
                "date": d,
                "taken": random.choice([True, True, True, False]), # 75% compliance
                "scheduled": True
            })
        result.append({
            "medication_name": m,
            "days": days
        })
    return result

@router.get("/voice/{patient_id}")
async def get_voice_analytics(patient_id: uuid.UUID, db: Session = Depends(get_db)):
    return {
        "rate": 0.85, # 85% response rate
        "total_initiated": 40,
        "total_responded": 34
    }
