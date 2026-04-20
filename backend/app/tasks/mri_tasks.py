import asyncio
import logging
from uuid import UUID
from datetime import datetime
from app.celery_app import celery_app
from app.database.postgres import SessionLocal
from app.models.mri import PatientMRIScan, PatientMRIAnalysis, PatientSeverityHistory, ScanStatus, SeveritySource
from app.services.mri_inference_service import mri_inference_service
from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)

async def _analyze_mri_core(scan_id: str):
    """Core async logic for MRI analysis"""
    db = SessionLocal()
    try:
        # 1. Fetch scan
        scan = db.query(PatientMRIScan).filter(PatientMRIScan.id == scan_id).first()
        if not scan:
            logger.error(f"❌ Task: Scan {scan_id} not found")
            return

        # 2. Update status to processing
        scan.status = ScanStatus.processing
        scan.updated_at = datetime.utcnow()
        db.commit()

        # 3. Get signed URL for the provider (External or Local)
        # For now, we pass the storage path or a temporary signed URL
        file_url = storage_service.get_signed_url(scan.storage_path)
        
        # 4. Run Inference
        result = await mri_inference_service.analyze_scan(scan_id, file_url)

        # 5. Store Analysis Result
        analysis = PatientMRIAnalysis(
            scan_id=scan.id,
            model_version=result.model_version,
            predicted_level=result.predicted_level,
            confidence=result.confidence,
            is_uncertain=result.is_uncertain,
            probabilities=result.probabilities,
            analyzed_at=datetime.utcnow()
        )
        db.add(analysis)
        
        # 6. Create Severity History entry
        history = PatientSeverityHistory(
            patient_id=scan.patient_id,
            level_before=scan.patient.level,
            level_after=result.predicted_level,
            source=SeveritySource.mri_ai,
            reference_id=scan.id,
            is_confirmed=False,
            recorded_at=datetime.utcnow()
        )
        db.add(history)
        
        # 7. Atomic Commit & Refresh
        scan.status = ScanStatus.completed
        scan.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(analysis)
        
        logger.info(f"✅ Task: Analysis SAVED to DB. ID={analysis.id}, Level={analysis.predicted_level}")
        
        # Return payload for logging visibility
        return {
            "predicted_level": result.predicted_level,
            "confidence": result.confidence,
            "scan_id": str(scan_id),
            "analysis_id": str(analysis.id)
        }

    except Exception as e:
        logger.error(f"❌ Task: Analysis failed for scan {scan_id}: {e}")
        db.rollback()
        
        # Mark scan as failed
        scan = db.query(PatientMRIScan).filter(PatientMRIScan.id == scan_id).first()
        if scan:
            scan.status = ScanStatus.failed
            scan.updated_at = datetime.utcnow()
            db.commit()
            
    finally:
        db.close()

@celery_app.task(name="app.tasks.mri_tasks.analyze_mri_task", bind=True, max_retries=3)
def analyze_mri_task(self, scan_id: str):
    """Celery task wrapper for MRI analysis"""
    return asyncio.run(_analyze_mri_core(scan_id))
