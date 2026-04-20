import requests
import json
import os
import sys

# Using localhost since we will run this from the HOST machine which proxies to Docker
# Or we run it inside Docker using 'backend:8000'
# However, to be safe and consistent with the user's setup, we use 10.0.2.2 if on emulator, 
# but here we'll just run it against the backend service inside Docker.
BASE_URL = "http://localhost:8000"

def test_login(email, password):
    url = f"{BASE_URL}/auth/login"
    payload = {"email": email, "password": password}
    try:
        resp = requests.post(url, json=payload, timeout=5)
        if resp.status_code == 200:
            print(f"✅ Login successful for {email}")
            return resp.json()["access_token"]
        else:
            print(f"❌ Login failed for {email}: {resp.status_code} - {resp.text}")
            return None
    except Exception as e:
        print(f"❌ Error during login for {email}: {e}")
        return None

def test_doctor_dashboard(token):
    url = f"{BASE_URL}/doctor/dashboard"
    headers = {"Authorization": f"Bearer {token}"}
    try:
        resp = requests.get(url, headers=headers, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            print(f"✅ Doctor dashboard fetched. Total patients: {data['total']}")
            for p in data["patients"]:
                print(f"   - Patient: {p['full_name']} (ID: {p['patient_unique_id']})")
            return data
        else:
            print(f"❌ Doctor dashboard fetch failed: {resp.status_code} - {resp.text}")
            return None
    except Exception as e:
        print(f"❌ Error during doctor dashboard fetch: {e}")
        return None

def test_caretaker_dashboard(token):
    url = f"{BASE_URL}/caretaker/dashboard"
    headers = {"Authorization": f"Bearer {token}"}
    try:
        resp = requests.get(url, headers=headers, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            print(f"✅ Caretaker dashboard fetched. Patient: {data['patient_name']}")
            return data
        else:
            print(f"❌ Caretaker dashboard fetch failed: {resp.status_code} - {resp.text}")
            return None
    except Exception as e:
        print(f"❌ Error during caretaker dashboard fetch: {e}")
        return None

if __name__ == "__main__":
    # Note: Running this from INSIDE docker? Use backend:8000. 
    # Running from HOST? Use localhost:8000 (if exposed) or 127.0.0.1:8000.
    # Currently docker-compose exposes 8000 for backend.
    
    print("--- Starting verification ---")
    
    # 1. Doctor verification
    doc_token = test_login("test-doctor@example.com", "alzai_secure_password")
    if doc_token:
        test_doctor_dashboard(doc_token)
    
    print("\n---")
    
    # 2. Caretaker verification
    car_token = test_login("test-caretaker@example.com", "alzai_secure_password")
    if car_token:
        test_caretaker_dashboard(car_token)
    
    print("\n--- Verification Finished ---")
