
from app.database.postgres import SessionLocal
from app.models.patient_metric import PatientMetric
from sqlalchemy import select

def check_metrics():
    session = SessionLocal()
    try:
        # Patient ID from logs: 9d2e0181-ad62-47a2-b6f1-c64d3d228179
        patient_id = "9d2e0181-ad62-47a2-b6f1-c64d3d228179"
        statement = select(PatientMetric).where(PatientMetric.patient_id == patient_id).order_by(PatientMetric.recorded_date.desc()).limit(10)
        results = session.execute(statement)
        metrics = results.scalars().all()
        
        print(f"\n--- Latest Metrics for Patient {patient_id} ---")
        if not metrics:
            print("No metrics found for this patient.")
        for m in metrics:
            print(f"Date: {m.recorded_date} | Cognitive Score: {m.cognitive_score} | Wellness: {m.wellness_score}")
    finally:
        session.close()

if __name__ == "__main__":
    check_metrics()
