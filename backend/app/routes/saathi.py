from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.patient import Patient
from app.schemas.saathi import SAATHITalkResponse, SAATHIContext
from app.services import whisper_service, tts_service, saathi_engine, groq_service, memory_service, alert_service
import os
import tempfile
import uuid
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

router = APIRouter(tags=["saathi"])

@router.get("/greeting")
async def get_saathi_greeting(patient_id: str, db: Session = Depends(get_db)):
    """
    Generates a localized, warm greeting for the patient.
    """
    if not patient_id:
        raise HTTPException(400, "patient_id is required")
    try:
        uuid.UUID(patient_id)
    except ValueError:
        raise HTTPException(400, "Invalid patient_id format")

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(404, "Patient not found")
        
    # Get context (mood, family, etc)
    system_prompt = await saathi_engine.build_system_prompt(patient_id, patient, db)
    
    # Ask AI for a simple, warm greeting based on the current context and rules
    user_prompt = f"Give me a single, warm opening greeting for {patient.full_name} in {patient.language}. Keep it under 2 sentences."
    
    from app.services import ai_orchestrator
    ai_result = await ai_orchestrator.generate_response(system_prompt, user_prompt)
    
    return {
        "greeting": ai_result["text"],
        "voice_sample_url": patient.voice_sample_url
    }

@router.post("/talk", response_model=SAATHITalkResponse)
async def saathi_talk(
    patient_id: str = Form(...),
    audio: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    temp_path = None
    transcribed_text = "Hello" # Fallback
    detected_mood = "neutral"
    
    try:
        # 1-2. Save audio to temp file
        ext = os.path.splitext(audio.filename)[1] or ".m4a"
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as temp_file:
            content = await audio.read()
            temp_file.write(content)
            temp_path = temp_file.name

        # 3. Transcribe audio (Resilient)
        try:
            transcription = await whisper_service.transcribe_audio(temp_path)
            transcribed_text = transcription.get("text", "").strip()
            if not transcribed_text:
                transcribed_text = "I'm just listening."
        except Exception as we:
            logger.error(f"⚠️ SAATHI: Whisper transcription failed: {we}")
            transcribed_text = "[Audio input failed]"

        # 4. Get patient from DB
        patient_db_record = db.query(Patient).filter(Patient.id == patient_id).first()
        if not patient_db_record:
            raise HTTPException(404, "Patient not found")

        # 5. Build system prompt (Engine already has fallback)
        system_prompt = await saathi_engine.build_system_prompt(patient_id, patient_db_record, db)

        # 6. Call AI Orchestrator (Now with Redis cache fallback)
        from app.services import ai_orchestrator
        ai_result = await ai_orchestrator.generate_response(
            system_prompt, 
            transcribed_text,
            patient_id=patient_id
        )
        ai_response = ai_result["text"]

        # 7. Detect Mood
        detected_mood = saathi_engine.detect_mood_from_text(transcribed_text)

        # 8-9. TTS Audio Generation (Resilient)
        audio_url = ""
        try:
            slow_tts = (detected_mood == "agitated")
            audio_url = await tts_service.text_to_speech(
                ai_response, 
                patient_db_record.language, 
                slow=slow_tts, 
                patient_id=patient_id
            )
        except Exception as te:
            logger.error(f"⚠️ SAATHI: TTS generation failed: {te}")
            # audio_url remains empty, mobile will use text fallback

        # 10-12. Background updates (Safe — non-blocking to user response)
        try:
            memory_service.save_conversation_log(
                patient_id, 
                summary=transcribed_text[:100], 
                mood_detected=detected_mood, 
                initiated_by="patient"
            )
            memory_service.save_mood_log(patient_id, mood=detected_mood, summary=ai_response[:100], detected_by="saathi")
            await alert_service.publish_to_websocket(patient_id, {
                "event_type": "mood_updated",
                "mood": detected_mood,
                "timestamp": datetime.utcnow().isoformat()
            })
        except Exception as be:
            logger.error(f"⚠️ SAATHI: Background record saving failed: {be}")

        return SAATHITalkResponse(
            response=ai_response,
            audio_url=audio_url,
            mood=detected_mood
        )

    except Exception as e:
        logger.error(f"❌ SAATHI: Critical Talk failure: {e}")
        # Final safety net — never 500
        return SAATHITalkResponse(
            response="I'm right here with you. I'm just listening right now. How are you feeling?",
            audio_url="",
            mood="neutral"
        )
    finally:
        if temp_path and os.path.exists(temp_path):
            try: os.remove(temp_path)
            except: pass


@router.post("/checkin/morning")
async def saathi_morning_checkin(data: dict, db: Session = Depends(get_db)):
    return {
        "text": "Good morning! Did you sleep well?",
        "audio_url": "https://example.com/audio.mp3",
        "mood": "neutral"
    }

@router.post("/checkin/medication")
async def saathi_medication_checkin(data: dict, db: Session = Depends(get_db)):
    return {
        "text": "It's time for your morning medication. Have you taken it?",
        "audio_url": "https://example.com/audio2.mp3",
        "medications_due": []
    }

@router.post("/checkin/night")
async def saathi_night_checkin(data: dict, db: Session = Depends(get_db)):
    return {
        "text": "Good night! Time to rest.",
        "audio_url": "https://example.com/audio3.mp3",
        "mood": "neutral"
    }

@router.get("/context/{patient_id}", response_model=SAATHIContext)
async def get_saathi_context(patient_id: str, db: Session = Depends(get_db)):
    patient_db_record = db.query(Patient).filter(Patient.id == patient_id).first()
    system_prompt = await saathi_engine.build_system_prompt(patient_id, patient_db_record, db)
    tokens = saathi_engine._estimate_tokens(system_prompt)
    
    return SAATHIContext(
        system_prompt=system_prompt,
        token_count=tokens
    )
