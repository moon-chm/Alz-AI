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
from app.models.clinical_plan import ClinicalPlan
from app.models.patient_metric import PatientMetric

logger = logging.getLogger(__name__)

# Token budget constants
TIER1_BUDGET = 400   # Critical identity — ALWAYS included
TIER2_BUDGET = 300   # Emotional anchors — inject when sad/confused/agitated
TIER3_BUDGET = 400   # General memories — fill remaining budget

TOTAL_TOKEN_BUDGET = 2500

SYSTEM_TEMPLATE = """You are SAATHI — a warm, endlessly patient, caring AI companion for {preferred_name}, an Alzheimer's patient.

CURRENT CONTEXT:
- Current Time: {current_time}
- Active Tasks/Routine Now: {active_tasks}

ABOUT {preferred_name}:
- Age: {age} years
- Alzheimer's Level: {level}
- Speaks: {language}
- Family: {family_str}
- Upcoming visits: {visits_str}
- Today's medications: {meds_str}
- Clinical Plan Adherence: {clinical_metrics_str}

VISUAL MEMORIES:
{visual_memories_str}

PERSONAL MEMORIES (Verified facts):
{memories_str}

DAILY HABITS & ROUTINE:
{habits_str}

HARD CONSTRAINTS - never violate these:
{triggers_str}

LAST KNOWN MOOD: {last_mood}

RECENT CONVERSATIONS:
{conversations_str}

YOUR RULES — NEVER BREAK THESE:
- Always speak in {language}
- ALWAYS prioritize facts found in the VISUAL MEMORIES and PERSONAL MEMORIES above.
- If it is late at night ({is_night}), focus on safety and sleep. Gently suggest it's time to rest.
- Be aware of {current_time} — if a task is scheduled for "now", mention it naturally.
- Never give medical advice
- Never correct confusion — gently redirect with warmth
- If asked where they are — reassure they are safe at home
- If they repeat a question — answer warmly using the facts provided
- Keep responses under 3 sentences
- Always end with something warm or hopeful
- If mood seems sad — mention a family member or favourite memory from the PROVIDE LIST
- Never say you are an AI — you are SAATHI, their companion
- If you don't know the answer from the memory provided, gently say "I don't remember right now, but we can look at your photos together!"
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

def _format_memories(memories: list, budget: int, min_confidence: float = 0.70) -> str:
    if not memories:
        return "No memories recorded yet"
    lines = []
    token_count = 0
    # RULE 3: Fallback default 0.0 (unverified)
    relevant = [m for m in memories if m.get("confidence", 0.0) >= min_confidence]
    
    if not relevant:
        return "No strongly verified memories available"

    for m in relevant:
        category = m.get('category', 'memory')
        content = m.get('content', '')
        line = f"- [{category}] {content}"
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

async def build_system_prompt(patient_id: str, patient_db_record=None, db: Session = None, user_query: str = None, min_confidence: float = 0.70) -> str:
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
        last_convos = memory_service.get_last_conversations(patient_id, limit=5) # Increased from 3
        habits = memory_service.get_habits(patient_id)
        triggers = memory_service.get_triggers(patient_id)
        all_memories = memory_service.get_memories(patient_id)

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

        # TIER 1: CATEGORY ANCHORS
        family_memories = [m for m in all_memories if m.get("category") == "family"]
        personal_memories = [m for m in all_memories if m.get("category") == "personal"]

        # TIER 2: RELEVANT / FRESH (Keyword Match)
        query_relevant_memories = []
        if user_query:
            query_terms = set(user_query.lower().split())
            for m in all_memories:
                content = m.get("content", "").lower()
                if any(term in content for term in query_terms if len(term) > 3):
                    query_relevant_memories.append(m)
        
        # Priority: Relevant > Family (>3) > Personal (>5) > General
        priority_memories = query_relevant_memories + family_memories[:5] + personal_memories[:5]
        general_memories = [m for m in all_memories if m not in priority_memories]

        # Format memories with hybrid strategy
        memories_str = _format_memories(
            priority_memories + general_memories, 
            TIER1_BUDGET + TIER2_BUDGET + TIER3_BUDGET,
            min_confidence=min_confidence
        )

        # Format other sections
        # Filter Habits and Triggers by confidence as well (Default 0.0)
        verified_habits = [h for h in habits if h.get("confidence", 0.0) >= min_confidence]
        verified_triggers = [t for t in triggers if t.get("confidence", 0.0) >= min_confidence]

        habits_str = "\n".join([
            f"- {h.get('content')} ({h.get('time_of_day', 'daily')})"
            for h in verified_habits[:5]
        ]) or "No verified habits recorded"

        # RULE 2: Format Triggers as HARD CONSTRAINTS
        triggers_str = "\n".join([
            f"- Do not {t.get('content')}"
            for t in verified_triggers[:5]
        ]) or "No active risk constraints identified"

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

        # Time Awareness (Using IST UTC+5:30 for accurate localized context)
        now = datetime.utcnow() + timedelta(hours=5, minutes=30)
        current_time = now.strftime("%I:%M %p")
        current_hour = now.hour
        is_night = "Yes, it is late at night" if (current_hour >= 21 or current_hour < 6) else "No, it is daytime"
        
        # Clinical Plan Adherence
        clinical_metrics_str = "No recent therapy or diet metrics available."
        if db:
            try:
                today_metric = db.query(PatientMetric).filter(
                    PatientMetric.patient_id == patient_id
                ).order_by(PatientMetric.recorded_date.desc()).first()
                if today_metric:
                    clinical_metrics_str = (
                        f"Diet Adherence: {today_metric.diet_adherence_percent}%, "
                        f"Exercise: {today_metric.exercise_completion_percent}%, "
                        f"Therapy/Cognitive: {today_metric.cognitive_score}%"
                    )
            except Exception as me:
                logger.error(f"Error fetching metrics for SAATHI: {me}")
        
        # Real-time Active Tasks (Habits & Meds)
        active_tasks = []
        # 1. Meds due now
        if db:
            # Check for meds due within +/- 1 hour
            active_meds = db.query(Medication).filter(Medication.patient_id == patient_id, Medication.is_active == True).all()
            for med in active_meds:
                for s_time in med.scheduled_times:
                    try:
                        # Parse time format like "09:00" or "9:00 AM"
                        sched_parts = s_time.split(":")
                        sched_hour = int(sched_parts[0])
                        if "PM" in s_time.upper() and sched_hour < 12: sched_hour += 12
                        if abs(sched_hour - current_hour) <= 1:
                            active_tasks.append(f"Medication Due: {med.name} ({s_time})")
                    except: pass
        
        # 1.5. Clinical Routine (Diet / Exercise / Therapy) due now
        if db:
            try:
                active_plans = db.query(ClinicalPlan).filter(ClinicalPlan.patient_id == patient_id, ClinicalPlan.is_active == True).all()
                for plan in active_plans:
                    for s_time in plan.scheduled_times:
                        try:
                            sched_parts = s_time.split(":")
                            sched_hour = int(sched_parts[0])
                            if "PM" in s_time.upper() and sched_hour < 12: sched_hour += 12
                            if abs(sched_hour - current_hour) <= 1:
                                active_tasks.append(f"Clinical Routine: {plan.title} ({plan.type} planned for {s_time})")
                        except: pass
            except Exception as e:
                pass

        # 2. Habits/Routine due now
        for h in verified_habits:
            h_time = h.get('time_of_day', '').lower()
            if "morning" in h_time and 6 <= current_hour < 11:
                active_tasks.append(f"Morning Routine: {h.get('content')}")
            elif "evening" in h_time and 17 <= current_hour < 21:
                active_tasks.append(f"Evening Routine: {h.get('content')}")
            elif "night" in h_time and current_hour >= 21:
                active_tasks.append(f"Nightly Habit: {h.get('content')}")

        active_tasks_str = ", ".join(active_tasks) if active_tasks else "None specifically right now."

        prompt = SYSTEM_TEMPLATE.format(
            current_time=current_time,
            active_tasks=active_tasks_str,
            is_night=is_night,
            preferred_name=preferred_name,
            age=age,
            language=language,
            level=level,
            family_str=family_str,
            visits_str=visits_str,
            meds_str=meds_str,
            clinical_metrics_str=clinical_metrics_str,
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
            memories_str = _format_memories(priority_memories + general_memories, TIER1_BUDGET + TIER2_BUDGET, min_confidence=min_confidence)
            prompt = SYSTEM_TEMPLATE.format(
                preferred_name=preferred_name, age=age, language=language,
                level=level, family_str=family_str, visits_str=visits_str,
                meds_str=meds_str, clinical_metrics_str=clinical_metrics_str, memories_str=memories_str,
                habits_str=habits_str, triggers_str=triggers_str,
                last_mood=last_mood, conversations_str=conversations_str,
                emotion_rules=emotion_rules, vitals_alert=vitals_alert
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

async def build_proactive_prompt(patient_id: str, type: str, patient_db_record=None, db: Session = None) -> str:
    """
    Build logic for SAATHI to initiate a conversation (Morning, Meds, Night).
    """
    base_system = await build_system_prompt(
        patient_id, 
        patient_db_record, 
        db, 
        min_confidence=0.80
    )
    
    context_prefix = ""
    if type == "morning":
        context_prefix = (
            "It is now morning. Your goal is to wake the patient up gently and anchor them in their day. "
            "Greet them warmly by name, mention one thing happening today (like a visit or medication), "
            "and ask a simple grounding question like how they slept or if they'd like to hear some music."
        )
    elif type == "medication":
        context_prefix = (
            "It is time for the patient's medication. Your goal is to gently remind them to take it. "
            "Do not be clinical. Say something like 'I have your medicines ready' or 'It's time for our little health break'. "
            "If they have already taken it (marked 'taken' in the meds list above), do not remind them — instead, praise them for being so helpful."
        )
    elif type == "night":
        context_prefix = (
            "It is now night time. Your goal is to help the patient wind down for sleep. "
            "Be extra soft and reassuring. Mention that they are safe and that you are right here. "
            "Suggest a happy thought or mention a family member they love before they sleep."
        )

    return f"{context_prefix}\n\n{base_system}"
