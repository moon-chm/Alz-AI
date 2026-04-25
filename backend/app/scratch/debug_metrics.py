
from app.database.postgres import SessionLocal
from app.models.patient_metric import PatientMetric
from app.models.patient import Patient
from sqlalchemy import select, func

def debug_metrics():
    session = SessionLocal()
    try:
        # Check all patients
        patients_stmt = select(Patient)
        patients = session.execute(patients_stmt).scalars().all()
        print(f"Total Patients: {len(patients)}")
        for p in patients:
            print(f"ID: {p.id} | Name: {p.full_name}")

        # Check total metrics
        count_stmt = select(func.count()).select_from(PatientMetric)
        count = session.execute(count_stmt).scalar()
        print(f"\nTotal PatientMetric records: {count}")

        # If any metrics, show them
        if count > 0:
            all_stmt = select(PatientMetric).limit(20)
            all_m = session.execute(all_stmt).scalars().all()
            for m in all_m:
                print(f"Patient ID: {m.patient_id} | Date: {m.recorded_date} | Cognitive: {m.cognitive_score}")
    finally:
        session.close()

if __name__ == "__main__":
    debug_metrics()
