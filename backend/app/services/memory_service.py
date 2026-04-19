from app.database.neo4j import get_neo4j_session
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

# Freshness scoring constants
RECENT_MULTIPLIER = 1.5      # Last 30 days
OLD_MULTIPLIER = 0.7         # Older than 90 days

def _freshness_score(date_added_str: str) -> float:
    try:
        if not date_added_str:
            return 1.0
        date_added = datetime.fromisoformat(date_added_str)
        days_ago = (datetime.now() - date_added).days
        if days_ago <= 30:
            return RECENT_MULTIPLIER
        elif days_ago > 90:
            return OLD_MULTIPLIER
        return 1.0
    except:
        return 1.0

def get_patient(patient_id: str) -> dict:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id}) RETURN p",
            id=patient_id
        )
        record = result.single()
        return dict(record["p"]) if record else None

def get_family(patient_id: str) -> list:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})-[:HAS_FAMILY]->(f:FamilyMember) RETURN f",
            id=patient_id
        )
        return [dict(r["f"]) for r in result]

def get_memories(patient_id: str) -> list:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})-[:HAS_MEMORY]->(m:Memory) "
            "RETURN m ORDER BY m.date_added DESC",
            id=patient_id
        )
        memories = []
        for r in result:
            m = dict(r["m"])
            m["freshness_score"] = _freshness_score(m.get("date_added", ""))
            memories.append(m)
        # Sort by freshness score descending
        return sorted(memories, key=lambda x: x["freshness_score"], reverse=True)

def get_habits(patient_id: str) -> list:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})-[:HAS_HABIT]->(h:Habit) RETURN h",
            id=patient_id
        )
        return [dict(r["h"]) for r in result]

def get_triggers(patient_id: str) -> list:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})-[:TRIGGERED_BY]->(t:EmotionalTrigger) RETURN t",
            id=patient_id
        )
        return [dict(r["t"]) for r in result]

def get_last_mood(patient_id: str) -> dict | None:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})-[:HAS_MOOD]->(m:MoodLog) "
            "RETURN m ORDER BY m.timestamp DESC LIMIT 1",
            id=patient_id
        )
        record = result.single()
        return dict(record["m"]) if record else None

def get_last_conversations(patient_id: str, limit: int = 3) -> list:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})-[:HAD_CONVERSATION]->(c:ConversationLog) "
            "RETURN c ORDER BY c.timestamp DESC LIMIT $limit",
            id=patient_id, limit=limit
        )
        return [dict(r["c"]) for r in result]

def get_upcoming_visits(patient_id: str) -> list:
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})<-[v:VISITING_ON]-(f:FamilyMember) "
            "WHERE v.date >= date() "
            "RETURN f, v.date as visit_date, v.time as visit_time "
            "ORDER BY v.date ASC LIMIT 5",
            id=patient_id
        )
        visits = []
        for r in result:
            visit = dict(r["f"])
            visit["visit_date"] = str(r["visit_date"])
            visit["visit_time"] = str(r.get("visit_time", ""))
            visits.append(visit)
        return visits

def save_conversation_log(patient_id: str, summary: str, mood_detected: str, initiated_by: str):
    with get_neo4j_session() as session:
        session.run(
            "MERGE (p:Patient {id: $id}) "
            "CREATE (p)-[:HAD_CONVERSATION]->(c:ConversationLog {"
            "  timestamp: $timestamp, summary: $summary, "
            "  mood_detected: $mood, initiated_by: $initiated_by"
            "})",
            id=patient_id,
            timestamp=datetime.now().isoformat(),
            summary=summary,
            mood=mood_detected,
            initiated_by=initiated_by
        )

def save_mood_log(patient_id: str, mood: str, summary: str, detected_by: str):
    with get_neo4j_session() as session:
        session.run(
            "MERGE (p:Patient {id: $id}) "
            "CREATE (p)-[:HAS_MOOD]->(m:MoodLog {"
            "  mood: $mood, summary: $summary, "
            "  detected_by: $detected_by, timestamp: $timestamp"
            "})",
            id=patient_id,
            mood=mood,
            summary=summary,
            detected_by=detected_by,
            timestamp=datetime.now().isoformat()
        )

def create_memory_node(patient_id: str, content: str, category: str, added_by: str) -> dict:
    with get_neo4j_session() as session:
        result = session.run(
            "MERGE (p:Patient {id: $id}) "
            "CREATE (p)-[:HAS_MEMORY]->(m:Memory {"
            "  id: randomUUID(), content: $content, category: $category, "
            "  date_added: $date, added_by: $added_by"
            "}) RETURN m",
            id=patient_id,
            content=content,
            category=category,
            date=datetime.now().isoformat(),
            added_by=added_by
        )
        record = result.single()
        return dict(record["m"]) if record else {}

def update_memory_node(memory_id: str, content: str = None, category: str = None):
    updates = {}
    if content: updates["content"] = content
    if category: updates["category"] = category
    if not updates:
        return
    set_clause = ", ".join([f"m.{k} = ${k}" for k in updates.keys()])
    with get_neo4j_session() as session:
        session.run(
            f"MATCH (m:Memory {{id: $id}}) SET {set_clause}",
            id=memory_id, **updates
        )

def delete_memory_node(memory_id: str):
    with get_neo4j_session() as session:
        session.run("MATCH (m:Memory {id: $id}) DETACH DELETE m", id=memory_id)

def create_family_member(patient_id: str, name: str, relationship: str, phone: str) -> dict:
    with get_neo4j_session() as session:
        result = session.run(
            "MERGE (p:Patient {id: $id}) "
            "CREATE (p)-[:HAS_FAMILY]->(f:FamilyMember {"
            "  id: randomUUID(), name: $name, relationship: $relationship, phone: $phone"
            "}) RETURN f",
            id=patient_id, name=name, relationship=relationship, phone=phone
        )
        record = result.single()
        return dict(record["f"]) if record else {}