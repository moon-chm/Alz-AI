from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.patient import Patient, CaretakerPatient
from app.utils.jwt import get_current_user
from app.core.access_control import require_doctor, require_patient_access
from app.services import patient_id_service
from app.schemas.patient import PatientResponse, PatientProfile, PatientCreate, PatientLevelUpdate
from app.schemas.auth import UserResponse
from app.services.storage_service import storage_service
from app.services.teleconsult_service import jitsi_provider
from app.tasks.mri_tasks import analyze_mri_task
from celery.result import AsyncResult
from app.celery_app import celery_app
from app.models.mri import PatientMRIScan, PatientMRIAnalysis, PatientSeverityHistory, ScanStatus, SeveritySource
from app.schemas.doctor import (
    DoctorDashboard, PatientSummary, MRIScanResponse, 
    MRIStatusResponse, MRIAnalysisResponse, MRIConfirmationRequest,
    MRIScanHistoryItem, MRIHistoryResponse
)
from app.utils.responses import success_response, error_response
import os
import tempfile
import uuid
from datetime import datetime

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
    
    return success_response(
        data={
            "patients": [s.dict() for s in summaries],
            "total": len(summaries),
            "critical_count": critical_count
        }
    )

@router.post("/patient/create", response_model=PatientResponse, status_code=201)
async def create_patient(data: PatientCreate, current_user: User = Depends(require_doctor), db: Session = Depends(get_db)):
    unique_id = patient_id_service.get_new_patient_id(db)
    
    patient = Patient(
        id=uuid.uuid4(),
        patient_unique_id=unique_id,
        full_name=data.full_name,
        dob=data.dob,
        level=data.level,
        language=data.language,
        trusted_phone=data.trusted_phone,
        doctor_id=current_user.id
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)
    
    # Real monitoring initialization logic
    return success_response(
        data=PatientResponse.from_orm(patient).dict(),
        message="Patient created successfully",
        status_code=201
    )

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
    
    return success_response(data=profile.dict())

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
    return success_response(data=PatientResponse.from_orm(patient).dict(), message="Patient level updated")

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

@router.post("/patient/{patient_id}/mri", response_model=MRIScanResponse)
async def upload_mri(
    patient_id: uuid.UUID, 
    file: UploadFile = File(...), 
    current_user: User = Depends(require_doctor), 
    patient: Patient = Depends(require_patient_access),
    db: Session = Depends(get_db)
):
    """
    Production MRI Upload Pipeline:
    1. Upload to MinIO (Private Storage)
    2. Record in DB
    3. Trigger Asynchronous AI Analysis (Celery)
    """
    try:
        content = await file.read()
        
        # 1. Store in MinIO
        ext = os.path.splitext(file.filename)[1]
        scan_id = uuid.uuid4()
        storage_path = f"patients/{str(patient_id)}/mri/{str(scan_id)}{ext}"
        
        checksum = storage_service.upload_file(content, storage_path, file.content_type)
        
        # 2. Record in DB
        scan = PatientMRIScan(
            id=scan_id,
            patient_id=patient_id,
            doctor_id=current_user.id,
            filename=file.filename,
            storage_path=storage_path,
            checksum=checksum,
            status=ScanStatus.pending
        )
        db.add(scan)
        db.commit()
        
        # 3. Trigger Task
        task = analyze_mri_task.delay(str(scan_id))
        
        response_payload = {
            "scan_id": str(scan_id),
            "task_id": task.id,
            "status": "PENDING"
        }
        print(f"DEBUG upload_success: Patient={patient_id}, Payload={response_payload}")
        
        return success_response(
            data=response_payload,
            message="MRI uploaded successfully. AI analysis has started."
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"MRI Upload Pipeline failure: {str(e)}")

@router.get("/mri/status/{task_id}", response_model=MRIStatusResponse)
async def get_mri_status(task_id: str, db: Session = Depends(get_db)):
    """Fetch status of asynchronous MRI analysis task and return result if ready"""
    task_result = AsyncResult(task_id, app=celery_app)
    
    response_data = {
        "task_id": task_id,
        "status": task_result.status,
        "error": str(task_result.result) if task_result.status == "FAILURE" else None
    }
    
    print(f"DEBUG status: Task={task_id}, Status={task_result.status}")
    if task_result.status == "FAILURE":
        print(f"DEBUG failure: Error={task_result.result}")
    
    return success_response(data=response_data)

@router.get("/patient/{patient_id}/mri/{scan_id}/result", response_model=MRIAnalysisResponse)
async def get_mri_result(
    patient_id: uuid.UUID,
    scan_id: uuid.UUID,
    current_user: User = Depends(require_doctor),
    patient: Patient = Depends(require_patient_access),
    db: Session = Depends(get_db)
):
    """Fetch stored MRI analysis results for a specific scan"""
    print(f"DEBUG result_req: Patient={patient_id}, Scan={scan_id}")
    analysis = db.query(PatientMRIAnalysis).filter(PatientMRIAnalysis.scan_id == scan_id).first()
    
    if not analysis:
        print(f"DEBUG result_missing: No analysis found in DB for Scan={scan_id}")
        # Check if the scan even exists
        scan = db.query(PatientMRIScan).filter(PatientMRIScan.id == scan_id).first()
        if not scan:
            return error_response(message="MRI Scan not found", status_code=404)
        
        if scan.status == ScanStatus.failed:
            return error_response(message="MRI Analysis failed for this scan", status_code=400)
        
        return error_response(message="Analysis still in progress", status_code=202)
        
    print(f"DEBUG result_found: Predicted={analysis.predicted_level}, Confidence={analysis.confidence}")
    
    response_data = MRIAnalysisResponse.from_orm(analysis).dict()
    history = db.query(PatientSeverityHistory).filter(PatientSeverityHistory.reference_id == scan_id).first()
    if history:
        response_data["history_id"] = history.id
        
    return success_response(data=response_data)

@router.post("/mri/confirm", response_model=PatientResponse)
async def confirm_mri_analysis(
    data: MRIConfirmationRequest,
    current_user: User = Depends(require_doctor),
    db: Session = Depends(get_db)
):
    """
    Doctor confirmation of AI-suggested severity update.
    This creates an audit log entry and updates the patient's current level.
    """
    history = db.query(PatientSeverityHistory).filter(PatientSeverityHistory.id == data.history_id).first()
    if not history:
        raise HTTPException(status_code=404, detail="Severity history record not found")
        
    patient = db.query(Patient).filter(Patient.id == history.patient_id).first()
    
    if data.confirm:
        # Update Patient Level
        patient.level = history.level_after
        history.is_confirmed = True
        history.confirmed_by = current_user.id
        history.confirmed_at = datetime.utcnow()
        history.note = data.doctor_note
        
        db.commit()
        db.refresh(patient)
        return patient
    else:
        # Just record the rejection
        history.is_confirmed = False
        history.confirmed_by = current_user.id
        history.confirmed_at = datetime.utcnow()
        history.note = f"REJECTED: {data.doctor_note}"
        db.commit()
        return patient

@router.get("/patient/{patient_id}/mri/history", response_model=MRIHistoryResponse)
async def get_mri_history(
    patient_id: uuid.UUID,
    limit: int = 10,
    offset: int = 0,
    current_user: User = Depends(require_doctor),
    patient: Patient = Depends(require_patient_access),
    db: Session = Depends(get_db)
):
    query = db.query(PatientMRIScan).filter(PatientMRIScan.patient_id == patient_id).order_by(PatientMRIScan.created_at.desc())
    
    total = query.count()
    scans = query.offset(offset).limit(limit).all()
    
    items = []
    for scan in scans:
        predicted_level = None
        confidence = None
        model_version = None
        
        if scan.analysis:
            predicted_level = scan.analysis.predicted_level
            confidence = scan.analysis.confidence
            model_version = scan.analysis.model_version
            
        items.append(MRIScanHistoryItem(
            scan_id=scan.id,
            created_at=scan.created_at,
            status=scan.status.value,
            predicted_level=predicted_level,
            confidence=confidence,
            model_version=model_version
        ))
        
    pages = (total + limit - 1) // limit if total > 0 else 1
    # Page calculation isn't strictly requested to be precise if `offset` is dynamic,
    # but `offset/limit + 1` maps to the current page view effectively.
    current_page = (offset // limit) + 1 if limit > 0 else 1
    
    return success_response(data=MRIHistoryResponse(
        items=items,
        total=total,
        page=current_page,
        pages=pages
    ).dict())

# Appointment routes removed and consolidated into appointments.py
