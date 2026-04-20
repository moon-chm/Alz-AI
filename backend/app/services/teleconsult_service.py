import re
from app.config import settings

class TeleconsultProvider:
    def generate_meeting_link(self, appointment_id: str, patient_id: str) -> str:
        raise NotImplementedError

class JitsiProvider(TeleconsultProvider):
    def __init__(self):
        self.base_url = getattr(settings, "jitsi_base_url", "https://meet.jit.si").rstrip("/")

    def _sanitize(self, text: str) -> str:
        """Sanitizes IDs to ensure clean URLs (Mandatory per requirements)"""
        return re.sub(r"[^a-zA-Z0-9-]", "", str(text))

    def generate_meeting_link(self, appointment_id: str, patient_id: str) -> str:
        """
        Generates a deterministic and robust room URL: 
        https://meet.jit.si/alzai-clinical-{app_id}-{patient_id}
        """
        safe_app_id = self._sanitize(appointment_id)
        safe_patient_id = self._sanitize(patient_id)
        
        # Lengthening room name to prevent signaling collisions on public Jitsi
        room_name = f"alzai-clinical-{safe_app_id}-{safe_patient_id}"
        return f"{self.base_url}/{room_name}"

class TeleconsultService:
    def __init__(self):
        self.provider_type = getattr(settings, "teleconsult_provider", "jitsi").lower()
        if self.provider_type == "jitsi":
            self.provider = JitsiProvider()
        else:
            # Fallback/Default
            self.provider = JitsiProvider()

    def create_meeting(self, appointment_id: str, patient_id: str) -> str:
        return self.provider.generate_meeting_link(appointment_id, patient_id)

# Singleton instances
teleconsult_provider = TeleconsultService()
jitsi_provider = JitsiProvider()
