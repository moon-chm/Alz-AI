import os
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.patient import Patient, CaretakerPatient
from app.models.appointment import Appointment
from app.schemas.patient import PatientProfile, PatientResponse, PatientLevelUpdate
from app.schemas.doctor import DoctorDashboard, PatientSummary, MRIUploadResponse
from app.schemas.auth import UserResponse
from app.utils.jwt import get_current_user, require_doctor
from app.utils.access_control import require_patient_access
from app.services import patient_id_service
from app.services import cloudinary_service
from datetime import datetime
import uuid
import tempfile
import random

router = APIRouter()

@router.get("/dashboard", response_model=DoctorDashboard)
async def get_dashboard(current_user: User = Depends(require_doctor), db: Session = Depends(get_db)):
    patients = db.query(Patient).filter(Patient.doctor_id == current_user.id).all()
    summaries = []
    critical_count = 0
    
    for p in patients:
        # Simplified logic for mockup
        urgency = "green"
        last_mood = "neutral"
        if p.level == 3:
            urgency = "red"
            last_mood = "agitated"
            critical_count += 1
        elif p.level == 2:
            urgency = "amber"
            last_mood = "confused"
            
        summaries.append(PatientSummary(
            id=p.id,
            patient_unique_id=p.patient_unique_id,
            full_name=p.full_name,
            level=p.level,
            language=p.language,
            urgency=urgency,
            last_mood=last_mood,
            last_checkin=datetime.utcnow()
        ))
    
    # Sort red first, amber second, green last
    order = {"red": 0, "amber": 1, "green": 2}
    summaries.sort(key=lambda x: order[x.urgency])
    
    return DoctorDashboard(
        patients=summaries,
        total=len(summaries),
        critical_count=critical_count
    )

@router.post("/patient/create", response_model=PatientResponse, status_code=201)
async def create_patient(data: dict, current_user: User = Depends(require_doctor), db: Session = Depends(get_db)):
    # Validate payload
    expected_fields = ["full_name", "dob", "level", "language", "trusted_phone"]
    if not all(field in data for field in expected_fields):
        raise HTTPException(status_code=400, detail="Missing required fields")
        
    unique_id = patient_id_service.get_new_patient_id(db)
    
    patient = Patient(
        id=uuid.uuid4(),
        patient_unique_id=unique_id,
        full_name=data["full_name"],
        dob=data["dob"],
        level=int(data["level"]),
        language=data["language"],
        trusted_phone=data["trusted_phone"],
        doctor_id=current_user.id
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)
    
    # Create Neo4j Node logic would be called here via memory_service.create_patient(patient)
    return patient

@router.get("/patient/{patient_id}", response_model=PatientProfile)
async def get_patient_profile(
    patient_id: uuid.UUID, 
    current_user: User = Depends(get_current_user), 
    patient: Patient = Depends(require_patient_access),
    db: Session = Depends(get_db)
):
    profile = PatientProfile.from_orm(patient)
    profile.doctor_info = UserResponse.from_orm(patient.doctor)
    
    caretaker_links = db.query(CaretakerPatient).filter(CaretakerPatient.patient_id == patient.id).all()
    caretaker_list = []
    for link in caretaker_links:
        caretaker = db.query(User).filter(User.id == link.caretaker_id).first()
        if caretaker:
            caretaker_list.append(UserResponse.from_orm(caretaker))
            
    profile.caretaker_info = caretaker_list
    
    return profile

@router.put("/patient/{patient_id}/level", response_model=PatientResponse)
async def update_patient_level(
    patient_id: uuid.UUID, 
    data: PatientLevelUpdate, 
    current_user: User = Depends(require_doctor), 
    patient: Patient = Depends(require_patient_access),
    db: Session = Depends(get_db)
):
    patient.level = data.level
    db.commit()
    db.refresh(patient)
    return patient

@router.get("/patient/{patient_id}/analytics")
async def get_patient_analytics(
    patient_id: uuid.UUID, 
    current_user: User = Depends(get_current_user), 
    patient: Patient = Depends(require_patient_access),
    db: Session = Depends(get_db)
):
    return {
        "status": "success",
        "data": "Analytics data structure placeholder",
        "patient_name": patient.full_name
    }

@router.post("/patient/{patient_id}/mri", response_model=MRIUploadResponse)
async def upload_mri(
    patient_id: uuid.UUID, 
    file: UploadFile = File(...), 
    current_user: User = Depends(require_doctor), 
    patient: Patient = Depends(require_patient_access),
    db: Session = Depends(get_db)
):
        
    # Save to temp file
    temp_path = None
    try:
        ext = os.path.splitext(file.filename)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_path = temp_file.name
            
        # Upload to Cloudinary
        folder = f"mri-scans/{str(patient_id)}"
        url = await cloudinary_service.upload_file(temp_path, folder, "image")
        
        # Mocking deepface/AI result since deepface_service isn't fully prompted
        mock_results = ["Early Mild Cognitive Impairment", "Normal Aging", "Moderate Alzheimer's Pathology"]
        result_text = random.choice(mock_results)
        
        return MRIUploadResponse(
            result=result_text,
            confidence=random.uniform(0.80, 0.99),
            timestamp=datetime.utcnow()
        )
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

# Appointment routes removed and consolidated into appointments.py
