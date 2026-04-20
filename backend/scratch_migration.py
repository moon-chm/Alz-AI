from sqlalchemy import text
from app.database.postgres import engine, Base
from app.models.patient import Patient
from app.models.adherence_log import AdherenceLog

print("Starting migration...")

with engine.begin() as conn:
    # 1. Add timezone to patients if not exists
    try:
        conn.execute(text("ALTER TABLE patients ADD COLUMN timezone VARCHAR DEFAULT 'Asia/Kolkata' NOT NULL"))
        print("Added timezone column to patients.")
    except Exception as e:
        print(f"Skipping timezone column (might already exist): {e}")

    # 2. Update AdherenceLog table
    # Since it's a dev environment, we drop and recreate to apply the unique constraint and new column safely
    try:
        conn.execute(text("DROP TABLE IF EXISTS adherence_logs"))
        print("Dropped old adherence_logs table.")
    except Exception as e:
        print(f"Error dropping table: {e}")

    # 3. Create all tables (this will pick up the new schema for AdherenceLog)
    Base.metadata.create_all(bind=engine)
    print("Recreated tables with new schema.")

print("Migration completed.")
