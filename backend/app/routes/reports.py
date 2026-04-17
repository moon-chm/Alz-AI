from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.appointment import Appointment
from app.models.patient import Patient
from app.utils.jwt import get_current_user
from app.models.user import User
import uuid
from datetime import datetime

router = APIRouter(tags=["reports"])

@router.post("/pdf")
async def generate_pdf(data: dict, current_user: User = Depends(get_current_user)):
    # Expected data: patient_id, period_days
    # Mocking pdf_service
    return {
        "download_url": f"https://example.com/reports/{data.get('patient_id')}_report.pdf",
        "generated_at": datetime.utcnow().isoformat()
    }

@router.get("/pre-appointment/{appointment_id}")
async def get_pre_appointment_brief(appointment_id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    app = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not app: raise HTTPException(404, "Appointment not found")
    
    patient = db.query(Patient).filter(Patient.id == app.patient_id).first()
    
    return {
        "patient_name": patient.full_name,
        "patient_id": str(patient.id),
        "mood_trend": ["neutral", "confused", "neutral", "happy", "neutral", "agitated", "neutral"],
        "medication_adherence": "82%",
        "top_insights": [
            "Patient showed increased confusion in the evenings (Sundowning pattern detected).",
            "Consistent adherence to morning medications.",
            "SAATHI interactions have improved mood generally."
        ],
        "unresolved_alerts": 2,
        "recent_conversations": [
            {"date": "2026-04-05", "summary": "Talked about old job, felt happy."},
            {"date": "2026-04-04", "summary": "Couldn't find glasses, was slightly agitated."},
            {"date": "2026-04-03", "summary": "Had a normal chat about weather."}
        ]
    }
