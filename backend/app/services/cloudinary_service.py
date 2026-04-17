import cloudinary
import cloudinary.uploader
import cloudinary.utils
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Initialize Cloudinary on import
if settings.cloudinary_cloud_name:
    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True
    )

# Folder patterns:
# patient-photos/{patient_id}/
# audio-responses/{patient_id}/
# tablet-photos/{patient_id}/
# mri-scans/{patient_id}/
# face-encodings/{patient_id}/

async def upload_file(file_path: str, folder: str, resource_type: str = "auto") -> str:
    result = cloudinary.uploader.upload(
        file_path, folder=folder, resource_type=resource_type
    )
    return result["secure_url"]

async def upload_audio(file_path: str, folder: str = "audio-responses") -> str:
    result = cloudinary.uploader.upload(
        file_path, folder=folder, resource_type="video"  # Cloudinary treats audio as video
    )
    return result["secure_url"]

async def delete_file(public_id: str) -> bool:
    try:
        cloudinary.uploader.destroy(public_id)
        return True
    except Exception as e:
        logger.error(f"Cloudinary delete error: {e}")
        return False

async def get_signed_url(public_id: str, expires_in: int = 3600) -> str:
    return cloudinary.utils.private_download_url(
        public_id, "pdf", expires_at=expires_in
    )
