from sqlalchemy.orm import Session
from app.models.medication import Medication
from app.models.patient import Patient
from app.services import memory_service
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

async def calculate_wellness_score(db: Session, patient_id: str) -> dict:
    """
    Calculate a heuristic-based Wellness Score (0-100).
    Aggregates data from Mood Logs, Medication Adherence, and Vitals.
    """
    score = 85  # Base score
    insights = []
    
    try:
        # 1. Mood Analysis (Neo4j)
        last_mood = memory_service.get_last_mood(patient_id)
        if last_mood:
            mood = last_mood.get('mood', 'neutral').lower()
            if mood == 'agitated':
                score -= 15
                insights.append("Increased agitation detected in recent conversations.")
            elif mood == 'depressed' or mood == 'sad':
                score -= 10
                insights.append("Signs of low mood or withdrawal noted.")
            elif mood == 'happy' or mood == 'calm':
                score += 5
                insights.append("Patient appears positive and engaged.")

        # 2. Medication Adherence (Mock/Postgres)
        # For now, we look at the number of active medications
        meds_count = db.query(Medication).filter(Medication.patient_id == patient_id, Medication.is_active == True).count()
        if meds_count > 0:
            # Heuristic: If they have many meds, complexity is high
            if meds_count > 5:
                insights.append("Complex medication schedule; ensure strict adherence.")
        
        # 3. Vitals Heuristics
        # Note: In a real system, we'd fetch trend data from Redis/TimescaleDB
        # Mocking a stable vital check
        current_hr = 72
        if current_hr > 100:
            score -= 10
            insights.append("Elevated heart rate detected.")
            
        # Ensure score is within bounds
        score = max(0, min(100, score))
        
        # Determine status
        status = "Stable"
        if score < 50:
            status = "Critical"
        elif score < 75:
            status = "Fair"
            
        return {
            "score": score,
            "status": status,
            "insights": insights,
            "last_updated": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error calculating wellness score: {e}")
        return {
            "score": 0,
            "status": "Unknown",
            "insights": ["Error processing patient data."],
            "last_updated": datetime.utcnow().isoformat()
        }
