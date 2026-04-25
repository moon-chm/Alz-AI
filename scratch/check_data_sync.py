from sqlalchemy import create_engine, text
import json

# Database configuration (matching docker-compose/env)
DB_URL = "postgresql://postgres:postgres@localhost:5432/alzai"

def check_fetched_data():
    engine = create_engine(DB_URL)
    with engine.connect() as conn:
        print("Checking recent data in tables...")
        
        # 1. Check Patients
        patients = conn.execute(text("SELECT id, full_name, patient_unique_id FROM patients LIMIT 5")).fetchall()
        print(f"\nTotal Patients Checked: {len(patients)}")
        for p in patients:
            print(f"- {p.full_name} ({p.patient_unique_id}) | ID: {p.id}")

        if not patients:
            print("No patients found in DB.")
            return

        # 2. Check Vitals (The main sync table)
        vitals_count = conn.execute(text("SELECT COUNT(*) FROM vitals")).scalar()
        print(f"\nTotal Vital Readings in DB: {vitals_count}")
        
        if vitals_count > 0:
            latest_vitals = conn.execute(text("""
                SELECT v.hr, v.steps, v.recorded_at, p.full_name 
                FROM vitals v 
                JOIN patients p ON v.patient_id = p.id 
                ORDER BY v.recorded_at DESC LIMIT 5
            """)).fetchall()
            print("\nLatest 5 Vital Readings:")
            for v in latest_vitals:
                print(f"  [{v.recorded_at}] {v.full_name}: HR={v.hr}, Steps={v.steps}")

        # 3. Check Patient Metrics (Wellness/Adherence)
        metrics_count = conn.execute(text("SELECT COUNT(*) FROM patient_metrics")).scalar()
        print(f"\nTotal Analytics Metrics in DB: {metrics_count}")
        
        if metrics_count > 0:
            latest_metrics = conn.execute(text("""
                SELECT m.recorded_date, m.wellness_score, m.cognitive_score, p.full_name 
                FROM patient_metrics m 
                JOIN patients p ON m.patient_id = p.id 
                ORDER BY m.recorded_date DESC, m.created_at DESC LIMIT 5
            """)).fetchall()
            print("\nLatest 5 Analytics Snapshots:")
            for m in latest_metrics:
                print(f"  [{m.recorded_date}] {m.full_name}: Wellness={m.wellness_score}, Cognitive={m.cognitive_score}")

if __name__ == "__main__":
    check_fetched_data()
