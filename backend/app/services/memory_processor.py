import logging
import json
from app.services import ai_orchestrator
from app.services import memory_service, embedding_service
from app.database.postgres import get_db, SessionLocal
from app.models.patient import Patient
from app.models.failure_log import FailureLog

logger = logging.getLogger(__name__)

EXTRACTION_PROMPT = """You are a Memory Specialist for an Alzheimer's companion.
Extract new, meaningful facts or memories about the patient from this conversation segment.

CATEGORIES:
- personal: Significant past events, life stories, achievements.
- family: Names, relationships, sentiments about family members.
- habit: Repeated actions, dietary preferences, sleep patterns.
- trigger: Things that cause distress, confusion, or joy.

CONVERSATION:
Patient: {user_message}
SAATHI: {ai_response}

INSTRUCTIONS:
1. Only extract new, verifiable facts.
2. Do not include existing knowledge mentioned as a reminder.
3. Be concise (max 15 words per fact).
4. Return as a JSON list: [{"content": "fact here", "category": "category"}]
5. If nothing meaningful is found, return [].

OUTPUT JSON ONLY."""

SUMMARY_PROMPT = """Summarize this interaction with an Alzheimer's patient in 1 sentence for a memory log. Use 3rd person.

CONVERSATION:
Patient: {user_message}
SAATHI: {ai_response}"""

async def _find_similar_memory(patient_id: str, new_content: str, category: str, new_emb: list[float] = None):
    """
    Find most semantically similar memory within a category. 
    Returns (best_match_node, score, new_emb)
    """
    if not new_emb:
        new_emb = await embedding_service.get_embedding(new_content)
    
    existing = []
    if category.lower() == "habit":
        existing = memory_service.get_habits(patient_id)
    elif category.lower() == "trigger":
        existing = memory_service.get_triggers(patient_id)
    else:
        existing = memory_service.get_memories(patient_id)
        
    best_match = None
    best_score = 0.0
    
    if new_emb:
        for old in existing:
            old_emb = old.get('embedding')
            if not old_emb: continue
            
            score = embedding_service.cosine_similarity(new_emb, old_emb)
            if score > best_score:
                best_score = score
                best_match = old
            
    return best_match, best_score, new_emb

async def process_conversation_memory(patient_id: str, user_message: str, ai_response: str):
    """
    Asynchronously extract memories and summarize conversation.
    """
    try:
        # 1. Generate Summary
        summary_result = await ai_orchestrator.generate_response(
            SUMMARY_PROMPT.format(user_message=user_message, ai_response=ai_response),
            "Summarize the interaction."
        )
        summary = summary_result.get("text", user_message[:100])
        
        memory_service.save_conversation_log(
            patient_id, 
            summary=summary, 
            mood_detected="neutral",
            initiated_by="patient"
        )

        # 2. Extract Discrete Memories
        extraction_result = await ai_orchestrator.generate_response(
            EXTRACTION_PROMPT.format(user_message=user_message, ai_response=ai_response),
            "Extract new memories."
        )
        
        raw_extraction = extraction_result.get("text", "[]")
        # Clean markdown
        if "```json" in raw_extraction:
            raw_extraction = raw_extraction.split("```json")[1].split("```")[0].strip()
        elif "```" in raw_extraction:
            raw_extraction = raw_extraction.split("```")[1].split("```")[0].strip()
            
        try:
            memories = json.loads(raw_extraction)
            if isinstance(memories, list):
                for m in memories:
                    content = m.get("content")
                    category = m.get("category", "personal")
                    if content:
                        # RULE 1: Semantic Reuse Logic (0.85 Threshold)
                        best_match, best_score, new_emb = await _find_similar_memory(patient_id, content, category)
                        
                        if best_score > 0.85:
                            # REINFORCE EXISTING
                            current_conf = best_match.get('confidence', 0.60)
                            # RULE 1: Nudge +0.05, Cap 0.95
                            new_conf = min(0.95, current_conf + 0.05)
                            
                            if category.lower() == "habit":
                                memory_service.update_habit_node(best_match['id'], confidence=new_conf, inc_mentions=True)
                            elif category.lower() == "trigger":
                                memory_service.update_trigger_node(best_match['id'], confidence=new_conf, inc_mentions=True)
                            else:
                                memory_service.update_memory_node(best_match['id'], confidence=new_conf, inc_mentions=True)
                            
                            logger.info(f"🔄 SAATHI: Reinforced {category} for {patient_id} (Score: {best_score:.2f}): {content}")
                        else:
                            # CREATE NEW
                            if category.lower() == "habit":
                                memory_service.create_habit_node(
                                    patient_id, content=content, added_by="saathi_autonomous", 
                                    confidence=0.60, embedding=new_emb
                                )
                            elif category.lower() == "trigger":
                                memory_service.create_trigger_node(
                                    patient_id, content=content, trigger_type="emotional", 
                                    added_by="saathi_autonomous", confidence=0.60, embedding=new_emb
                                )
                            else:
                                memory_service.create_memory_node(
                                    patient_id, content=content, category=category, 
                                    added_by="saathi_autonomous", confidence=0.60, embedding=new_emb
                                )
                            logger.info(f"💾 SAATHI: Autonomous {category} saved for {patient_id}: {content}")
        except Exception as je:
            raise ValueError(f"JSON parsing failed: {je} | Raw: {raw_extraction}")

    except Exception as e:
        logger.error(f"❌ SAATHI: Memory Processor failed: {e}")
        with SessionLocal() as db:
            log = FailureLog(
                patient_id=patient_id,
                service="memory_processor",
                error_message=str(e),
                raw_input={"user_message": user_message, "ai_response": ai_response}
            )
            db.add(log)
            db.commit()
