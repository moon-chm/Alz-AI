from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.patient import CaretakerPatient
from app.models.user import User
from app.utils.jwt import get_current_token_payload
import uuid

router = APIRouter(tags=["family"])

@router.get("/members")
async def list_family_members(
    patient_id: uuid.UUID = None,
    payload: dict = Depends(get_current_token_payload),
    db: Session = Depends(get_db)
):
    # Ensure we have a patient_id
    patient_id = patient_id or payload.get("patient_id")
    if not patient_id:
        raise HTTPException(400, "patient_id not found in token or query params.")
        
    # Query for all caretakers linked to this patient
    links = db.query(CaretakerPatient).filter(
        CaretakerPatient.patient_id == patient_id, 
        CaretakerPatient.link_status == "active"
    ).all()
    
    members = []
    for link in links:
        caretaker = db.query(User).filter(User.id == link.caretaker_id).first()
        if caretaker:
            members.append({
                "id": str(caretaker.id),
                "name": caretaker.full_name or "Unknown",
                "relationship": link.relationship or "Family Member",
                "photo_url": "", # Placeholder or check for actual photo
                "phone": caretaker.phone or "",
                "is_primary": link.is_primary or False
            })
            
    return members
