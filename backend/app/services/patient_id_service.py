from app.utils.patient_id import generate_patient_id
from sqlalchemy.orm import Session

def get_new_patient_id(db: Session) -> str:
    """
    Generate and return a unique patient ID using the Nexus 2.0 format.
    Ensures new patients are assigned the 'PAT-' prefix for security and non-predictability.
    """
    return generate_patient_id(db, prefix="PAT")
