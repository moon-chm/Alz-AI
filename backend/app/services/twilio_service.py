from twilio.rest import Client
from app.config import settings
import logging

logger = logging.getLogger(__name__)

client = None
if settings.twilio_account_sid and settings.twilio_auth_token:
    client = Client(settings.twilio_account_sid, settings.twilio_auth_token)

async def send_sms(to_phone: str, message: str) -> bool:
    """
    Send standard SMS via Twilio.
    to_phone: Indian phone number (10 digits)
    """
    if not client:
        logger.warning(f"Twilio not configured, skipping SMS to {to_phone}: {message}")
        return False
        
    try:
        # Format for Indian numbers if only 10 digits provided
        to_formatted = to_phone.strip()
        if len(to_formatted) == 10:
            to_formatted = f"+91{to_formatted}"
        elif not to_formatted.startswith('+'):
            to_formatted = f"+{to_formatted}"

        # Use TWILIO_FROM_NUMBER or fallback to a stripped version of WHATSAPP_FROM
        from_number = getattr(settings, 'twilio_from_number', None)
        if not from_number:
            from_number = settings.twilio_whatsapp_from.replace('whatsapp:', '')

        msg = client.messages.create(
            body=message,
            from_=from_number,
            to=to_formatted
        )
        print(f"✅ PROFESSIONAL SMS SENT TO {to_phone}: SID {msg.sid}")
        logger.info(f"SMS sent to {to_phone}: SID {msg.sid}")
        return True
    except Exception as e:
        logger.error(f"Twilio SMS error: {e}")
        return False

async def send_whatsapp(to_phone: str, message: str) -> bool:
    """
    Send WhatsApp message via Twilio.
    to_phone: Indian phone number (10 digits, no country code)
    """
    if not client:
        logger.warning(f"Twilio not configured, skipping WhatsApp to {to_phone}: {message}")
        return False
        
    try:
        to_formatted = f"whatsapp:+91{to_phone.strip()}"
        msg = client.messages.create(
            body=message,
            from_=settings.twilio_whatsapp_from,
            to=to_formatted
        )
        print(f"✅ PROFESSIONAL WHATSAPP SENT TO {to_phone}: SID {msg.sid}")
        logger.info(f"WhatsApp sent to {to_phone}: SID {msg.sid}")
        return True
    except Exception as e:
        logger.error(f"Twilio WhatsApp error: {e}")
        return False

# Message templates
def sos_message(patient_name: str, lat: float, lng: float) -> str:
    return (
        f"🚨 SOS ALERT: {patient_name} has triggered an emergency.\n"
        f"Last known location: {lat:.4f}, {lng:.4f}\n"
        f"Google Maps: https://maps.google.com/?q={lat},{lng}\n"
        f"Call immediately."
    )

def medication_missed_message(patient_name: str, medication_name: str, scheduled_time: str) -> str:
    return (
        f"⚠️ {patient_name} has not confirmed taking {medication_name} "
        f"(scheduled at {scheduled_time}). Please check on them."
    )

def agitated_mood_message(patient_name: str, mood_summary: str) -> str:
    return (
        f"⚠️ {patient_name} has been showing agitated mood for 30+ minutes.\n"
        f"SAATHI detected: {mood_summary}\nPlease check in."
    )

def daily_digest_message(patient_name: str, meds_taken: int, avg_mood: str, conversations: int) -> str:
    return (
        f"Good morning! Daily update for {patient_name}:\n"
        f"✅ Medications taken: {meds_taken}\n"
        f"📊 Mood: {avg_mood}\n"
        f"💬 SAATHI conversations: {conversations}"
    )
