import asyncio
import sys
import os

# Add parent directory to path to import app modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services import memory_processor
from app.database.neo4j import get_neo4j_session
from app.services import memory_service

async def simulate_extraction():
    patient_id = "test-patient-uuid" # We'll just use a dummy string, Neo4j handles it
    user_msg = "My grandson Rahul is coming to see me tomorrow. He is a doctor now."
    ai_res = "That sounds wonderful! Dr. Rahul must be so busy, it will be lovely to spend time with him."

    print(f"--- Simulating Extraction ---")
    print(f"User: {user_msg}")
    print(f"AI: {ai_res}")
    
    # Run the processor
    await memory_processor.process_conversation_memory(patient_id, user_msg, ai_res)
    
    print("\n--- Verifying Neo4j Results ---")
    with get_neo4j_session() as session:
        result = session.run(
            "MATCH (p:Patient {id: $id})-[:HAS_MEMORY]->(m:Memory) "
            "RETURN m ORDER BY m.date_added DESC LIMIT 5",
            id=patient_id
        )
        found = False
        for record in result:
            m = record["m"]
            found = True
            print(f"Fact Found: [{m['category']}] {m['content']}")
            print(f"Confidence: {m.get('confidence')}")
            print(f"Added By: {m.get('added_by')}")
            print("-" * 20)
        
        if not found:
            print("No new memories found in Neo4j.")

if __name__ == "__main__":
    asyncio.run(simulate_extraction())
