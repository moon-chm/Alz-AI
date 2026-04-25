from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User
from app.models.clinical_plan import ClinicalPlan
from app.utils.jwt import get_current_user
import uuid

router = APIRouter(tags=["clinical_plans"])

@router.get("/{patient_id}")
async def list_plans(
    patient_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    return db.query(ClinicalPlan).filter(ClinicalPlan.patient_id == patient_id, ClinicalPlan.is_active == True).all()

@router.post("/")
async def create_plan(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plan = ClinicalPlan(
        patient_id=data["patient_id"],
        type=data["type"],
        title=data["title"],
        description=data["description"],
        scheduled_times=data["scheduled_times"],
        created_by=current_user.id
    )
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return plan

@router.delete("/{id}")
async def delete_plan(
    id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plan = db.query(ClinicalPlan).filter(ClinicalPlan.id == id).first()
    if not plan: raise HTTPException(404, "Plan not found")
    
    plan.is_active = False
    db.commit()
    return {"status": "deleted"}
