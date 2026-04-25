import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database.postgres import SessionLocal
from app.models.failure_log import FailureLog

def check_failures():
    with SessionLocal() as db:
        logs = db.query(FailureLog).order_by(FailureLog.timestamp.desc()).limit(5).all()
        print(f"--- FAILURE LOGS (Total: {len(logs)}) ---")
        for log in logs:
            print(f"[{log.timestamp}] Service: {log.service}")
            print(f"Error: {log.error_message}")
            print(f"Input: {log.raw_input}")
            print("-" * 30)

if __name__ == "__main__":
    check_failures()
