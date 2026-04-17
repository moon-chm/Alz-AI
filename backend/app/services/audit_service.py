from uuid import UUID
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.audit_log import AuditLog
import logging

logger = logging.getLogger(__name__)

def log_event(
    db: Session,
    action: str,
    actor_id: UUID,
    patient_id: UUID = None,
    target_id: str = None,
    metadata: dict = None
):
    """
    Standardized audit logging for sensitive system events.
    """
    try:
        log_entry = AuditLog(
            user_id=actor_id,
            patient_id=patient_id,
            action=action,
            entity_type="SYSTEM_EVENT",
            entity_id=target_id,
            new_value=metadata,
            timestamp=datetime.utcnow()
        )
        db.add(log_entry)
        db.commit()
        logger.info(f"[AUDIT] {action} by {actor_id} on {target_id}")
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to write audit log: {e}")

# Specialized log helpers
def log_otp_event(db: Session, phone: str, event_type: str, success: bool):
    """Logs OTP sent, failed, or verified."""
    log_event(
        db=db,
        action=f"OTP_{event_type.upper()}",
        actor_id=None, # Global system actor
        target_id=phone,
        metadata={"success": success, "ts": datetime.utcnow().isoformat()}
    )
