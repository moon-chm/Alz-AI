from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.services import memory_service
from app.utils.jwt import get_current_user
from app.models.user import User
import uuid

router = APIRouter(tags=["memory"])

@router.get("/{patient_id}")
async def get_memories(patient_id: str, current_user: User = Depends(get_current_user)):
    return memory_service.get_memories(patient_id)

@router.post("/family")
async def create_family(data: dict, current_user: User = Depends(get_current_user)):
    # Expected data: patient_id, name, relationship, phone
    return memory_service.create_family_member(
        data["patient_id"], data["name"], data["relationship"], data["phone"]
    )

@router.put("/family/{id}")
async def update_family(id: str, data: dict, current_user: User = Depends(get_current_user)):
    # Neo4j update family logic would go here
    return {"status": "success", "id": id}

@router.get("/mood/{patient_id}")
async def get_mood(patient_id: str, current_user: User = Depends(get_current_user)):
    return memory_service.get_last_mood(patient_id)

@router.get("/conversations/{patient_id}")
async def get_conversations(patient_id: str, current_user: User = Depends(get_current_user)):
    return memory_service.get_last_conversations(patient_id)
