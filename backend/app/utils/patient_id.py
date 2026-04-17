import random
import string
from sqlalchemy.orm import Session
from app.models.patient import Patient

def validate_patient_id(candidate: str) -> dict:
    """
    Validates the format of a Patient ID.
    Returns metadata about the format.
    """
    if candidate.startswith("PAT-") and len(candidate) == 10:
        return {"format": "nexus_2_0", "is_legacy": False}
    elif candidate.startswith("ALZ-") and "-" in candidate:
        return {"format": "legacy", "is_legacy": True}
    return {"format": "unknown", "is_legacy": None}

def generate_patient_id(db: Session, prefix: str = "PAT") -> str:
    """
    Generate a non-predictable, unique patient ID.
    Format: PAT-XXXXXX (6 alphanumeric characters)
    Includes collision detection with 20 retries.
    """
    max_attempts = 20
    
    for _ in range(max_attempts):
        # Generate 6 random alphanumeric characters (UC and Digits)
        chars = string.ascii_uppercase + string.digits
        random_suffix = ''.join(random.choices(chars, k=6))
        candidate = f"{prefix}-{random_suffix}"
        
        # Check uniqueness in DB
        existing = db.query(Patient).filter(
            Patient.patient_unique_id == candidate
        ).first()
        
        if not existing:
            return candidate
            
    raise ValueError("Could not generate unique patient ID after 20 attempts. System entropy low.")
