from uuid import UUID
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User, RoleEnum
from app.models.patient import Patient, CaretakerPatient
from app.utils.jwt import get_current_user

async def require_patient_access(patient_id: UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Enforces strict ownership and access control for patient data.
    - Doctors: Must be the supervising doctor for this patient.
    - Caretakers: Must have a verified link in the CaretakerPatient table.
    """
    # 1. Check if Patient Exists
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    # 2. Doctor Access Logic
    if current_user.role == RoleEnum.doctor:
        if patient.doctor_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You are not the supervising doctor for this patient."
            )
        return patient

    # 3. Caretaker Access Logic
    if current_user.role == RoleEnum.caretaker:
        link = db.query(CaretakerPatient).filter(
            CaretakerPatient.caretaker_id == current_user.id,
            CaretakerPatient.patient_id == patient_id
        ).first()
        
        if not link:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You are not authorized to view this patient's data."
            )
        return patient

    # 4. Fallback for undefined roles
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Access denied: Role-based authorization failed."
    )
