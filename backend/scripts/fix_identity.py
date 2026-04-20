import sys
import os
from datetime import datetime
import uuid

# Add the backend directory to the path so we can import from app
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database.postgres import SessionLocal
from app.models.user import User, RoleEnum, UserStatus
from app.models.patient import Patient, CaretakerPatient
from app.utils.password import hash_password

def migrate():
    db = SessionLocal()
    try:
        # 1. Create Doctor User
        doctor_email = "test-doctor@example.com"
        doctor = db.query(User).filter(User.email == doctor_email).first()
        
        if not doctor:
            print(f"Creating doctor: {doctor_email}")
            doctor = User(
                id=uuid.uuid4(),
                email=doctor_email,
                password_hash=hash_password("alzai_secure_password"),
                role=RoleEnum.doctor,
                full_name="Dr. Alz AI",
                phone="+919999999999",
                status=UserStatus.active,
                nmc_number="NMC-001"
            )
            db.add(doctor)
            db.flush()
        else:
            print(f"Doctor {doctor_email} already exists.")
            # Ensure it is active
            doctor.status = UserStatus.active

        # 2. Reassign Patients to Doctor
        patients = db.query(Patient).all()
        for patient in patients:
            if patient.doctor_id != doctor.id:
                print(f"Reassigning patient {patient.full_name} to doctor {doctor_email}")
                patient.doctor_id = doctor.id
        
        # 3. Mark all caretaker-patient links as verified
        links = db.query(CaretakerPatient).all()
        for link in links:
            if not link.verified_at:
                print(f"Verifying link for caretaker {link.caretaker_id} and patient {link.patient_id}")
                link.verified_at = datetime.utcnow()
        
        db.commit()
        print("Identity and link migration completed successfully.")
        
    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    migrate()
