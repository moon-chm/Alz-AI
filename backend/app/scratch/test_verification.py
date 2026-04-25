import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services import memory_service
from app.services.confidence_service import ConfidenceService
from app.database.neo4j import get_neo4j_session

def test_verification_flow():
    patient_id = "9d2e0181-ad62-47a2-b6f1-c64d3d228179" # Aryan Shinde
    
    print("--- TESTING VERIFICATION FLOW ---")
    
    # 1. Create a dummy low-confidence memory
    print("Creating dummy autonomous memory...")
    new_mem = memory_service.create_memory_node(
        patient_id, 
        content="He likes to walk in the garden after dinner.", 
        category="habit",
        added_by="saathi_autonomous",
        confidence=0.60
    )
    mem_id = new_mem["id"]
    print(f"Created Memory ID: {mem_id} (Conf: {new_mem.get('confidence')})")

    # 2. Simulate Caretaker Approval
    print("\nSimulating Caretaker Approval...")
    ConfidenceService.process_caretaker_feedback(mem_id, 0.60, is_correct=True)
    
    # 3. Verify Update in Neo4j
    with get_neo4j_session() as session:
        res = session.run("MATCH (m:Memory {id: $id}) RETURN m", id=mem_id).single()
        updated_mem = res["m"]
        print(f"Updated Confidence in Neo4j: {updated_mem.get('confidence')}")
        
        if updated_mem.get('confidence') == 1.0:
            print("✅ SUCCESS: Confidence capped at 1.0 correctly.")
        else:
            print(f"❌ FAILURE: Expected 1.0, got {updated_mem.get('confidence')}")

    # 4. Clean up
    memory_service.delete_memory_node(mem_id)
    print("\nTest Memory Deleted.")

if __name__ == "__main__":
    test_verification_flow()
