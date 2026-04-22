from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.patient import CaretakerPatient
from app.utils.jwt import get_current_user
from app.services import alert_service
import uuid

router = APIRouter(tags=["help"])

@router.post("/sos")
async def trigger_sos(data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    patient_id = data.get("patient_id")
    if not patient_id:
        # Check if current user is a patient
        if current_user.role == "patient":
            patient_id = current_user.id
        else:
            # Check for linked patient if caretaker
            link = db.query(CaretakerPatient).filter(CaretakerPatient.caretaker_id == current_user.id).first()
            if not link: raise HTTPException(404, "No patient linked to trigger SOS")
            patient_id = link.patient_id

    # Create SOS alert
    alert = await alert_service.create_alert(
        db=db,
        patient_id=patient_id,
        alert_type="sos",
        severity=5,
        message="Patient triggered SOS alert via app",
        extra_data={"latitude": data.get("latitude"), "longitude": data.get("longitude")}
    )
    return {"status": "sos_triggered", "alert_id": str(alert.id), "patient_id": str(patient_id)}
