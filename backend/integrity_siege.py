import requests
import concurrent.futures
import uuid
import time
from datetime import datetime

BASE_URL = "http://localhost:8000" # Assuming internal or proxy access
# Note: In a real docker environment, we use the service name. 
# For this script run locally or via docker exec, we need to be careful.

def get_auth_token(identifier, role):
    # This assumes a test user or bypass exists
    # For now, we'll assume we have a valid token or we bypass auth for validation if possible
    # We'll use a placeholder or real login if credentials known
    return "TEST_TOKEN"

def confirm_meddose(patient_id, medication_id, scheduled_time, token):
    url = f"{BASE_URL}/patient/medication/confirm"
    headers = {"Authorization": f"Bearer {token}"}
    payload = {
        "patient_id": str(patient_id),
        "medication_id": str(medication_id),
        "scheduled_time": scheduled_time
    }
    try:
        resp = requests.post(url, json=payload, headers=headers, timeout=5)
        return resp.status_code, resp.json()
    except Exception as e:
        return 500, str(e)

def run_concurrency_siege(patient_id, medication_id, scheduled_time, token):
    print(f"--- Starting Concurrency Siege (20 requests) ---")
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
        futures = [executor.submit(confirm_meddose, patient_id, medication_id, scheduled_time, token) for _ in range(20)]
        for future in concurrent.futures.as_completed(futures):
            results.append(future.result())
    
    success_count = len([r for r in results if r[1].get("status") == "ok"])
    idempotent_count = len([r for r in results if r[1].get("status") == "already_confirmed"])
    error_count = len([r for r in results if r[0] >= 400 and r[1].get("status") not in ["ok", "already_confirmed"]])
    
    print(f"Results: Success={success_count}, AlreadyConfirmed={idempotent_count}, Errors={error_count}")
    return success_count, idempotent_count

if __name__ == "__main__":
    # This script is meant to be run where it can reach the backend.
    # We will use a dummy UUIDs since we are testing logic and unique constraints.
    # In a real test, use a valid patient_id from the DB.
    pass
