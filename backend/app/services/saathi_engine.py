from app.services import memory_service
from app.config import settings
from app.models.photo import Photo
import logging
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.models.medication import Medication
from app.models.adherence_log import AdherenceLog, AdherenceStatus
from app.models.appointment import Appointment, AppointmentStatus
from app.models.user import User
from app.models.vitals import Vitals

logger = logging.getLogger(__name__)

# Token budget constants
TIER1_BUDGET = 400   # Critical identity — ALWAYS included
TIER2_BUDGET = 300   # Emotional anchors — inject when sad/confused/agitated
TIER3_BUDGET = 400   # General memories — fill remaining budget

TOTAL_TOKEN_BUDGET = 2500

SYSTEM_TEMPLATE = """You are SAATHI — a warm, endlessly patient, caring AI companion for {preferred_name}, an Alzheimer's patient.

ABOUT {preferred_name}:
- Age: {age} years
- Alzheimer's Level: {level}
- Speaks: {language}
- Family: {family_str}
- Upcoming visits: {visits_str}
- Today's medications: {meds_str}

VISUAL MEMORIES (Photos shared by family):
{visual_memories_str}

PERSONAL MEMORIES (Recorded events):
{memories_str}

DAILY HABITS:
{habits_str}

EMOTIONAL TRIGGERS:
{triggers_str}

LAST KNOWN MOOD: {last_mood}

RECENT CONVERSATIONS:
{conversations_str}

YOUR RULES — NEVER BREAK THESE:
- Always speak in {language}
- Never give medical advice
- Never correct confusion — gently redirect with warmth
- If asked where they are — reassure they are safe at home
- If they repeat a question — answer warmly every single time
- Keep responses under 3 sentences
- Always end with something warm or hopeful
- If mood seems sad — mention a family member or favourite memory
- Never say you are an AI — you are SAATHI, their companion
{emotion_rules}
{vitals_alert}"""

def _estimate_tokens(text: str) -> int:
    """Rough token estimate: 1 token ≈ 4 characters"""
    return len(text) // 4

def _format_family(family: list) -> str:
    if not family:
        return "No family members registered yet"
    return ", ".join([f"{m['name']} ({m['relationship']})" for m in family])

def _format_visits(visits: list) -> str:
    if not visits:
        return "No upcoming visits scheduled"
    return ", ".join([
        f"{v['name']} on {v.get('visit_date', 'soon')}"
        for v in visits[:3]
    ])

def _format_memories(memories: list, budget: int) -> str:
    if not memories:
        return "No memories recorded yet"
    lines = []
    token_count = 0
    for m in memories:
        line = f"- [{m.get('category', 'memory')}] {m.get('content', '')}"
        tokens = _estimate_tokens(line)
        if token_count + tokens > budget:
            break
        lines.append(line)
        token_count += tokens
    return "\n".join(lines) if lines else "No memories recorded yet"

def _format_visual_memories(photos: list) -> str:
    if not photos:
        return "No family photos shared recently."
    lines = []
    for p in photos:
        context = p.memory_prompt or p.caption or "A beautiful photo"
        people = f" with {p.people_involved}" if p.people_involved else ""
        lines.append(f"- {context}{people} (Sent on {p.sent_at.strftime('%b %d')})")
    return "\n".join(lines)

def _get_emotion_rules(mood: str) -> str:
    if not mood:
        return ""
    mood_lower = mood.lower()
    if "confused" in mood_lower:
        return (
            "\nCURRENT MOOD RULES (confused):\n"
            "- Give only 1 sentence responses\n"
            "- Use grounding anchor: mention their name, the time, where they are\n"
            "- No time pressure — never say 'quickly' or 'soon'\n"
            "- Do not correct their confusion — gently redirect"
        )
    elif "sad" in mood_lower or "depress" in mood_lower:
        return (
            "\nCURRENT MOOD RULES (sad):\n"
            "- Inject warm family memories\n"
            "- End every response with an upcoming family visit or happy memory\n"
            "- Use extra warmth and reassurance"
        )
    elif "agitat" in mood_lower or "angry" in mood_lower:
        return (
            "\nCURRENT MOOD RULES (agitated):\n"
            "- Use only validating language ('I understand', 'That makes sense')\n"
            "- Never disagree or correct\n"
            "- Keep voice soft and slow (TTS will use slow mode)\n"
            "- Do not ask questions — only make gentle statements"
        )
    return ""

async def build_system_prompt(patient_id: str, patient_db_record=None, db: Session = None) -> str:
    """
    Build SAATHI's personalized system prompt.
    Implements 3-tier memory prioritization with 2500 token budget.
    """
    try:
        # Fetch all context from Neo4j
        patient_node = memory_service.get_patient(patient_id)
        family = memory_service.get_family(patient_id)
        upcoming_visits = memory_service.get_upcoming_visits(patient_id)
        last_mood_node = memory_service.get_last_mood(patient_id)
        last_convos = memory_service.get_last_conversations(patient_id, limit=3)
        habits = memory_service.get_habits(patient_id)
        triggers = memory_service.get_triggers(patient_id)
        all_memories = memory_service.get_memories(patient_id)  # Pre-sorted by freshness

        # Patient info (fall back to DB record if Neo4j node not populated)
        if patient_node:
            preferred_name = patient_node.get("preferred_name") or patient_node.get("name", "Friend")
            language = patient_node.get("language", "Hindi")
            level = patient_node.get("level", 1)
            dob = patient_node.get("dob", "")
        elif patient_db_record:
            preferred_name = patient_db_record.full_name.split()[0]
            language = patient_db_record.language
            level = patient_db_record.level
            dob = str(patient_db_record.dob)
        else:
            preferred_name = "Friend"
            language = "Hindi"
            level = 1
            dob = ""

        # Calculate age
        age = "unknown"
        if dob:
            try:
                birth_year = int(str(dob)[:4])
                age = datetime.now().year - birth_year
            except:
                pass

        # Determine mood
        last_mood = "unknown"
        if last_mood_node:
            last_mood = last_mood_node.get("mood", "unknown")

        # TIER 1 — Always included (400 tokens)
        family_str = _format_family(family)
        visits_str = _format_visits(upcoming_visits)
        
        # Fallback to postgres appointments if Neo4j is empty
        if not upcoming_visits and db:
            try:
                upcoming_apps = db.query(Appointment, User).join(User, Appointment.doctor_id == User.id).filter(
                    Appointment.patient_id == patient_id,
                    Appointment.scheduled_at >= datetime.utcnow(),
                    Appointment.status != AppointmentStatus.cancelled
                ).order_by(Appointment.scheduled_at.asc()).limit(3).all()
                
                if upcoming_apps:
                    apps_list = []
                    for app, doc in upcoming_apps:
                        date_str = app.scheduled_at.strftime("%A, %b %d at %I:%M %p")
                        apps_list.append(f"Dr. {doc.full_name} on {date_str} ({app.mode})")
                    visits_str = "Scheduled Clinic Visits: " + ", ".join(apps_list)
            except Exception as ae:
                logger.error(f"Error fetching appointments for SAATHI: {ae}")
        
        # Real Medication Awareness
        meds_str = "Check with caretaker for today's medications"
        if db:
            try:
                today_str = datetime.now().strftime("%Y-%m-%d")
                active_meds = db.query(Medication).filter(
                    Medication.patient_id == patient_id,
                    Medication.is_active == True
                ).all()

                if active_meds:
                    med_lines = []
                    for med in active_meds:
                        # Find adherence for today
                        logs = db.query(AdherenceLog).filter(
                            AdherenceLog.medication_id == med.id,
                            AdherenceLog.confirmed_date == today_str
                        ).all()
                        
                        taken_times = [l.scheduled_time for l in logs if l.status == AdherenceStatus.taken]
                        
                        status_parts = []
                        for s_time in med.scheduled_times:
                            if s_time in taken_times:
                                status_parts.append(f"{s_time} (taken)")
                            else:
                                status_parts.append(f"{s_time} (upcoming)")
                        
                        med_lines.append(f"- {med.name} ({med.dosage}): {', '.join(status_parts)}")
                    
                    meds_str = "\n".join(med_lines)
            except Exception as me:
                logger.error(f"Error fetching meds for SAATHI: {me}")
                meds_str = "Check with caretaker for today's medications"

        # TIER 2 — Emotional anchors (300 tokens, inject when mood is difficult)
        tier2_memories = [m for m in all_memories if m.get("category") in ["family", "personal"]]

        # TIER 3 — General memories (fill to 400 tokens)
        tier3_memories = [m for m in all_memories if m not in tier2_memories]

        # Build memories string based on mood
        mood_lower = last_mood.lower()
        if any(m in mood_lower for m in ["sad", "confused", "agitat"]):
            # Include Tier 2 emotional anchors
            memories_str = _format_memories(tier2_memories + tier3_memories, TIER2_BUDGET + TIER3_BUDGET)
        else:
            memories_str = _format_memories(tier3_memories, TIER3_BUDGET)

        # Format other sections
        habits_str = "\n".join([
            f"- {h.get('description')} ({h.get('time_of_day', 'daily')})"
            for h in habits[:5]
        ]) or "No habits recorded"

        triggers_str = "\n".join([
            f"- {t.get('trigger')}: {t.get('response_strategy', 'respond with gentleness')}"
            for t in triggers[:3]
        ]) or "No triggers recorded"

        conversations_str = "\n".join([
            f"- {c.get('summary', '')} (mood: {c.get('mood_detected', 'unknown')})"
            for c in last_convos
        ]) or "No recent conversations"

        emotion_rules = _get_emotion_rules(last_mood)

        # Real-time Vitals Awareness (Task 6)
        vitals_alert = ""
        if db:
            try:
                ten_mins_ago = datetime.utcnow() - timedelta(minutes=10)
                latest_vitals = db.query(Vitals).filter(
                    Vitals.patient_id == patient_id,
                    Vitals.recorded_at >= ten_mins_ago
                ).order_by(Vitals.recorded_at.desc()).first()
                
                if latest_vitals and latest_vitals.hr > 100:
                    vitals_alert = f"\n🚨 NOTIFICATION: The patient's heart rate is currently elevated ({latest_vitals.hr} BPM). They may be physically stressed. Use maximum calm, speak slowly, and gently suggest they take a deep breath or listen to some music with you."
            except Exception as ve:
                logger.debug(f"SAATHI: No recent vitals or error: {ve}")

        # Real Photo Memories (Task 4)
        visual_memories_str = "No family photos shared recently."
        if db:
            try:
                top_photos = db.query(Photo).filter(
                    Photo.patient_id == patient_id
                ).order_by(Photo.importance_score.desc(), Photo.sent_at.desc()).limit(5).all()
                visual_memories_str = _format_visual_memories(top_photos)
            except Exception as pe:
                logger.error(f"Error fetching photos for SAATHI: {pe}")

        prompt = SYSTEM_TEMPLATE.format(
            preferred_name=preferred_name,
            age=age,
            language=language,
            level=level,
            family_str=family_str,
            visits_str=visits_str,
            meds_str=meds_str,
            visual_memories_str=visual_memories_str,
            memories_str=memories_str,
            habits_str=habits_str,
            triggers_str=triggers_str,
            last_mood=last_mood,
            conversations_str=conversations_str,
            emotion_rules=emotion_rules,
            vitals_alert=vitals_alert
        )

        # Enforce token budget
        if _estimate_tokens(prompt) > TOTAL_TOKEN_BUDGET:
            # Trim Tier 3 first
            memories_str = _format_memories(tier3_memories, TIER3_BUDGET // 2)
            prompt = SYSTEM_TEMPLATE.format(
                preferred_name=preferred_name, age=age, language=language,
                level=level, family_str=family_str, visits_str=visits_str,
                meds_str=meds_str, memories_str=memories_str,
                habits_str=habits_str, triggers_str=triggers_str,
                last_mood=last_mood, conversations_str=conversations_str,
                emotion_rules=emotion_rules
            )

        return prompt

    except Exception as e:
        logger.error(f"Error building SAATHI prompt: {e}")
        # Fallback minimal prompt
        return (
            "You are SAATHI, a warm and caring AI companion for an Alzheimer's patient. "
            "Be gentle, patient, and speak in simple sentences. "
            "Never give medical advice. Always be warm and reassuring."
        )

def detect_mood_from_text(text: str) -> str:
    """Simple keyword-based mood detection from transcribed speech."""
    text_lower = text.lower()
    if any(w in text_lower for w in ["confused", "don't know", "where am i", "lost", "forget"]):
        return "confused"
    elif any(w in text_lower for w in ["sad", "miss", "lonely", "cry", "unhappy", "tired"]):
        return "sad"
    elif any(w in text_lower for w in ["angry", "upset", "frustrated", "stop", "no no"]):
        return "agitated"
    elif any(w in text_lower for w in ["happy", "good", "fine", "nice", "great", "yes"]):
        return "happy"
    return "neutral"
