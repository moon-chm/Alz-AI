import redis
import json
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.alert import Alert
from app.config import settings
from app.services import twilio_service
import logging

logger = logging.getLogger(__name__)
try:
    r = redis.from_url(settings.redis_url, decode_responses=True)
except:
    r = None

DEDUP_TTL = 3600  # 1 hour

async def create_alert(
    db: Session,
    patient_id: str,
    alert_type: str,
    severity: int,
    message: str,
    created_by: str = None,
    patient_name: str = None,
    caretaker_phone: str = None,
    extra_data: dict = None
) -> Alert:
    """
    Create alert with priority routing:
    P5: synchronous Twilio + WebSocket immediately
    P4: queue to Redis critical queue  
    P3: in-app only
    P1-2: batch digest
    """
    # Deduplication check
    dedup_key = f"alert_dedup:{patient_id}:{alert_type}"
    if r:
        existing_count = r.get(dedup_key)
        
        if existing_count:
            count = int(existing_count) + 1
            r.setex(dedup_key, DEDUP_TTL, count)
            if count == 2:
                message = f"[REPEATED x2] {message}"
            else:
                logger.info(f"Suppressing duplicate alert: {alert_type} for {patient_id}")
                # Still create DB record but don't notify again
        else:
            r.setex(dedup_key, DEDUP_TTL, 1)

    # Create DB record
    alert = Alert(
        patient_id=patient_id,
        created_by=created_by,
        alert_type=alert_type,
        severity=severity,
        message=message
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)

    # Publish WebSocket event
    await publish_to_websocket(str(patient_id), {
        "event_type": "alert_created",
        "alert_id": str(alert.id),
        "severity": severity,
        "message": message,
        "timestamp": datetime.now().isoformat()
    })

    # Priority routing
    if severity == 5:
        # P5: immediate synchronous WhatsApp
        if caretaker_phone:
            msg = twilio_service.sos_message(
                patient_name or "Patient",
                extra_data.get("lat", 0) if extra_data else 0,
                extra_data.get("lng", 0) if extra_data else 0
            )
            await twilio_service.send_whatsapp(caretaker_phone, msg)
    
    elif severity == 4 and r:
        # P4: queue to critical Redis queue
        r.rpush("queue:critical", json.dumps({
            "job": "alert_dispatch",
            "alert_id": str(alert.id),
            "patient_id": str(patient_id),
            "caretaker_phone": caretaker_phone,
            "message": message
        }))
    
    elif severity <= 2 and r:
        # P1-2: batch digest queue
        r.rpush("queue:batch_digest", json.dumps({
            "patient_id": str(patient_id),
            "alert_type": alert_type,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }))

    return alert

async def acknowledge_alert(db: Session, alert_id: str, user_id: str) -> Alert:
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        raise ValueError(f"Alert {alert_id} not found")
    alert.is_acknowledged = True
    alert.acknowledged_by = user_id
    alert.acknowledged_at = datetime.utcnow()
    db.commit()
    db.refresh(alert)
    return alert

async def publish_to_websocket(patient_id: str, event_dict: dict):
    """Publish event to Redis pub/sub channel for WebSocket broadcast."""
    if not r: return
    try:
        channel = f"patient:{patient_id}:events"
        r.publish(channel, json.dumps(event_dict))
    except Exception as e:
        logger.error(f"WebSocket publish error: {e}")
