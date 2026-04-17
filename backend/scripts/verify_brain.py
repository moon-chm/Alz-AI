import asyncio
import os
import logging
from app.services import ai_orchestrator, saathi_engine
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

load_dotenv()

async def verify_system():
    print(" === FINAL SYSTEM VERIFICATION === ")
    patient_id = "22b3ba56-a0f0-4223-92a8-c8209c154faa" # Akay Kohali
    
    try:
        print(" [1/3] Building personalized prompt...")
        system_prompt = await saathi_engine.build_system_prompt(patient_id)
        
        print(" [2/3] Calling AI Orchestrator...")
        result = await ai_orchestrator.generate_response(system_prompt, "Who is visiting?")
        
        print("\n--- TEST RESULTS ---")
        print(f" AI Says: {result['text']}")
        print(f" Provider: {result['provider']}")
        print(f" Latency: {result['latency']}s")
        
        # Check for context keywords
        text = result['text']
        if "Arjun" in text or "Priya" in text or "son" in text.lower() or "daughter" in text.lower():
            print("\n [SUCCESS] Memory + AI + Graph connection is STABLE.")
        else:
            print("\n [WARNING] Connectivity exists but context injection response was generic.")

    except Exception as e:
        print(f"\n [ERROR] VERIFICATION FAILED: {str(e)}")

if __name__ == "__main__":
    asyncio.run(verify_system())
