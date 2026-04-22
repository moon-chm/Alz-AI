import uuid
import logging
from datetime import datetime
from sqlalchemy.orm import Session
from app.database.postgres import SessionLocal
from app.database.neo4j import get_neo4j_session
from app.models.user import User, RoleEnum, UserStatus
from app.models.patient import Patient, CaretakerPatient
from app.utils.password import hash_password

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def seed_postgres(db: Session):
    """
    Critical Path: Seed core authentication and relationship data.
    Must succeed for application to be considered 'ready'.
    """
    try:
        # 1. Check if seeding is already done (Idempotency)
        if db.query(User).filter(User.email == "test-caretaker@example.com").first():
            logger.info("[SEED] Postgres already seeded. Skipping.")
            return True

        logger.info("[SEED] Starting Postgres seeding...")

        # 2. Seed Default Users
        pwd = "password"
        hashed = hash_password(pwd)
        
        doctor = User(
            id=uuid.uuid4(),
            email="test-doctor@example.com",
            password_hash=hashed,
            role=RoleEnum.doctor,
            full_name="Dr. Sameer Kohali",
            phone="9876543200",
            status=UserStatus.active,
            nmc_number="NMC-12345",
            specialization="Neurologist"
        )
        db.add(doctor)
        
        caretaker = User(
            id=uuid.uuid4(),
            email="test-caretaker@example.com",
            password_hash=hashed,
            role=RoleEnum.caretaker,
            full_name="Arjun Kohali",
            phone="9876543210",
            status=UserStatus.active
        )
        db.add(caretaker)
        db.flush() # Ensure IDs are available

        # 3. Seed Default Patient
        patient = Patient(
            id=uuid.uuid4(),
            patient_unique_id="ALZ-001",
            full_name="Akay Kohali",
            dob=datetime(1955, 5, 15),
            trusted_phone="9876543210",
            language="Hindi",
            timezone="Asia/Kolkata",
            doctor_id=doctor.id,
            level=2
        )
        db.add(patient)
        db.flush()

        # 4. Link Caretaker to Patient
        link = CaretakerPatient(
            caretaker_id=caretaker.id,
            patient_id=patient.id,
            relationship="son",
            is_primary=True,
            verified_at=datetime.utcnow()
        )
        db.add(link)

        # 5. Seed Medications
        from app.models.medication import Medication
        meds = [
            Medication(
                patient_id=patient.id,
                name="Donepezil",
                dosage="10mg",
                scheduled_times=["08:00"],
                created_by=caretaker.id
            ),
            Medication(
                patient_id=patient.id,
                name="Memantine",
                dosage="5mg",
                scheduled_times=["08:00", "20:00"],
                created_by=caretaker.id
            )
        ]
        db.add_all(meds)
        
        db.commit()
        logger.info("[SEED] Postgres complete.")
        return True
    except Exception as e:
        db.rollback()
        logger.error(f"[SEED] Postgres FAILED: {e}")
        return False

def seed_neo4j():
    """
    Non-Critical Path: Sync relational data into the graph.
    Failure here does not stop the app.
    """
    try:
        db = SessionLocal()
        patients = db.query(Patient).all()
        db.close()

        if not patients:
            logger.warning("[SEED] Neo4j skipped: No patients found in Postgres.")
            return

        with get_neo4j_session() as session:
            for p in patients:
                # Merge Patient
                session.run("""
                    MERGE (p:Patient {id: $id})
                    SET p.name = $name, 
                        p.language = $lang, 
                        p.level = $level
                """, id=str(p.id), name=p.full_name, lang=p.language, level=p.level)
                
                # Basic Family relationships (static for demo)
                session.run("""
                    MATCH (p:Patient {id: $p_id})
                    MERGE (f:FamilyMember {name: "Arjun Kohali"})
                    SET f.relationship = "Son", f.phone = "+91 9876543210"
                    MERGE (p)-[:HAS_FAMILY]->(f)
                """, p_id=str(p.id))

        logger.info("[SEED] Neo4j complete.")
    except Exception as e:
        logger.warning(f"[SEED] Neo4j skipped/failed: {e}")

def orchestrate_seeding():
    """
    Main entry point for seeding.
    """
    from app.config import settings
    if settings.system_mode != "DEMO":
        logger.warning(f"[SEED] Skipping seeder: system_mode is {settings.system_mode}")
        return
        
    db = SessionLocal()
    try:
        pg_success = seed_postgres(db)
        if pg_success:
            seed_neo4j()
        else:
            # Critical path failure
            raise RuntimeError("Postgres seeding failed; blocking startup.")
    finally:
        db.close()
