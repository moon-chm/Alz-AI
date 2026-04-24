import asyncio
from app.services.twilio_service import send_whatsapp

# Phase 16 Detectors
def detect_sleep_patterns(patient_id: str): pass
def detect_mood_trends(patient_id: str): pass
def detect_medication_adherence(patient_id: str): pass
def detect_conversation_engagement(patient_id: str): pass
def predict_fall_risk(patient_id: str): pass
def predict_confusion_spike(patient_id: str): pass

# Phase 17 Jobs
async def alert_dispatch_job(payload: dict):
    retries = payload.get("retries", 0)
    try:
        # Check PostgreSQL
        # Call Whatsapp safely depending on DND window
        severity = payload.get("severity", 3)
        if severity == 4 and payload.get("contact"):
            await send_whatsapp(payload.get("contact"), f"URGENT: {payload.get('message')}")
    except Exception as e:
        if retries < 3:
            backoffs = [10, 30, 60]
            await asyncio.sleep(backoffs[retries])
            payload["retries"] = retries + 1
            await alert_dispatch_job(payload)

async def whatsapp_notification_job(payload: dict):
    retries = payload.get("retries", 0)
    try:
        send_whatsapp(payload.get("contact"), payload.get("message"))
    except Exception as e:
        if retries < 5:
            backoffs = [10, 30, 60, 120, 300]
            await asyncio.sleep(backoffs[retries])
            payload["retries"] = retries + 1
            await whatsapp_notification_job(payload)

async def pdf_generation_job(payload: dict):
    # From phase 16 service, renders natively
    pass

async def ai_fallback_retry_job(payload: dict):
    retries = payload.get("retries", 0)
    try:
        # Re-try groq context map
        pass
    except Exception as e:
        if retries < 1:
            await asyncio.sleep(300) # 5 min max window
            payload["retries"] = retries + 1
            await ai_fallback_retry_job(payload)

job_definitions_map = {
    "alert_dispatch_job": alert_dispatch_job,
    "whatsapp_notification_job": whatsapp_notification_job,
    "pdf_generation_job": pdf_generation_job,
    "ai_fallback_retry_job": ai_fallback_retry_job
}
