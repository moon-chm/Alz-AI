import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database.neo4j import get_neo4j_session
from app.services import memory_service

def inspect_patient_memory(patient_id: str):
    print(f"--- INSPECTING MEMORY FOR: {patient_id} ---")
    
    with get_neo4j_session() as session:
        # 1. Basic Patient Node
        patient = session.run("MATCH (p:Patient {id: $id}) RETURN p", id=patient_id).single()
        if patient:
            print(f"Patient Profile: {dict(patient['p'])}")
        else:
            print(f"Patient Node Not Found!")

        # 2. Family Members
        family = memory_service.get_family(patient_id)
        print(f"Family Members ({len(family)}):")
        for f in family:
            print(f"- {f.get('name')} ({f.get('relationship')})")

        # 3. Memories
        memories = memory_service.get_memories(patient_id)
        print(f"Memories ({len(memories)}):")
        for m in memories:
            print(f"- [{m.get('category')}] {m.get('content')} (Conf: {m.get('confidence', 1.0)})")

        # 4. Habits & Triggers
        habits = memory_service.get_habits(patient_id)
        triggers = memory_service.get_triggers(patient_id)
        print(f"Habits: {len(habits)} | Triggers: {len(triggers)}")

        # 5. Recent Conversations
        convos = memory_service.get_last_conversations(patient_id, limit=5)
        print(f"Recent Interactions ({len(convos)}):")
        for c in convos:
            print(f"- [{c.get('timestamp')}] {c.get('summary')} (Mood: {c.get('mood_detected')})")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python inspect_patient_memory.py <patient_id>")
        sys.exit(1)
    patient_id = sys.argv[1]
    inspect_patient_memory(patient_id)
