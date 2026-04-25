import logging
from app.services import memory_service

logger = logging.getLogger(__name__)

class ConfidenceService:
    # Constants for adjustments
    INCREMENT_CONFIRMATION = 0.40  # Caretaker says "Yes this is true"
    INCREMENT_REINFORCEMENT = 0.10 # Patient mentions it again
    DECREMENT_CONTRADICTION = 0.50 # Patient/Caretaker says "No that's wrong"
    MAX_CONFIDENCE = 1.0
    MIN_CONFIDENCE = 0.1

    @staticmethod
    def adjust_confidence(memory_id: str, current_confidence: float, adjustment: float):
        """
        Adjust confidence score for a memory node.
        """
        new_score = max(ConfidenceService.MIN_CONFIDENCE, min(ConfidenceService.MAX_CONFIDENCE, current_confidence + adjustment))
        memory_service.update_memory_node(memory_id, confidence=round(new_score, 2))
        logger.info(f"📈 CONFIDENCE: Memory {memory_id} adjusted from {current_confidence} to {new_score}")
        return new_score

    @staticmethod
    def process_caretaker_feedback(memory_id: str, current_confidence: float, is_correct: bool):
        """
        Handles explicit feedback from the caretaker UI.
        """
        adj = ConfidenceService.INCREMENT_CONFIRMATION if is_correct else -ConfidenceService.DECREMENT_CONTRADICTION
        return ConfidenceService.adjust_confidence(memory_id, current_confidence, adj)

    @staticmethod
    def process_implicit_reinforcement(memory_id: str, current_confidence: float):
        """
        Handles cases where conversation analysis confirms the memory again.
        """
        return ConfidenceService.adjust_confidence(memory_id, current_confidence, ConfidenceService.INCREMENT_REINFORCEMENT)
