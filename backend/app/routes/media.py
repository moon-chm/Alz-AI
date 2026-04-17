from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from app.services import cloudinary_service
import os
import tempfile
import uuid

router = APIRouter(tags=["media"])

@router.post("/upload")
async def upload_media(file: UploadFile = File(...)):
    if file.size > 10 * 1024 * 1024:
        raise HTTPException(400, "File too large (max 10MB)")
        
    content_type = file.content_type
    folder = "general"
    resource_type = "auto"
    
    if content_type.startswith("image/"):
        folder = "images"
    elif content_type.startswith("audio/"):
        folder = "audio-responses"
        resource_type = "video"
    elif content_type == "application/pdf":
        folder = "documents"
        
    temp_path = None
    try:
        ext = os.path.splitext(file.filename)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_path = temp_file.name
            
        url = await cloudinary_service.upload_file(temp_path, folder, resource_type)
        return {
            "url": url,
            "public_id": f"{folder}/{os.path.basename(temp_path)}",
            "resource_type": resource_type
        }
    except Exception as e:
        raise HTTPException(500, f"Upload failed: {str(e)}")
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@router.post("/face/register")
async def register_face(
    patient_id: str = Form(...),
    family_member_name: str = Form(...),
    file: UploadFile = File(...)
):
    # Mocking deepface_service as it wasn't fully specified
    return {
        "success": True,
        "encoding_url": f"https://example.com/encodings/{patient_id}_{uuid.uuid4()}.json"
    }

@router.post("/face/recognize")
async def recognize_face(
    patient_id: str = Form(...),
    file: UploadFile = File(...)
):
    # Mocking deepface_service
    return {
        "matched": True,
        "family_member": "Rohan (Son)",
        "confidence": 0.94
    }
