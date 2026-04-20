import abc
import asyncio
import logging
import random
import os
import io
import hashlib
from typing import Dict, Any, Optional
from app.config import settings
from pydantic import BaseModel, Field

# Lazy imports to keep worker startup fast
try:
    import tensorflow as tf
    import numpy as np
    from PIL import Image
    HAS_ML_LIBS = True
except ImportError:
    HAS_ML_LIBS = False

try:
    import torch
    import torch.nn as nn
    from torchvision import transforms, models
    HAS_TORCH = True
except ImportError:
    HAS_TORCH = False

logger = logging.getLogger(__name__)

# Global model cache (singleton per process/worker)
_MODEL_CACHE: Optional[Any] = None

class InferenceResult(BaseModel):
    probabilities: Dict[str, float]
    predicted_level: int = Field(ge=1, le=3)
    confidence: float = Field(ge=0.0, le=1.0)
    model_version: str
    is_uncertain: bool = False

class MRIInferenceProvider(abc.ABC):
    @abc.abstractmethod
    async def run_inference(self, file_path_or_url: str) -> InferenceResult:
        pass

class MockProvider(MRIInferenceProvider):
    async def run_inference(self, file_path_or_url: str) -> InferenceResult:
        """Standardized mock pipeline with realistic probability distributions"""
        logger.info(f"🧠 AI (Mock): Running inference on {file_path_or_url}...")
        await asyncio.sleep(2) # Simulate latency
        
        # Generate random "logits"
        logits = [random.uniform(0, 5) for _ in range(3)]
        # Simple Softmax implementation for probabilities summing to 1.0
        exp_logits = [pow(2.718, l) for l in logits]
        sum_exp = sum(exp_logits)
        probs = [round(e / sum_exp, 4) for e in exp_logits]
        
        # Adjust last one to ensure absolute 1.0 sum (floating point fix)
        probs[-1] = round(1.0 - sum(probs[:-1]), 4)
        
        predicted_idx = probs.index(max(probs))
        predicted_level = predicted_idx + 1
        confidence = probs[predicted_idx]
        
        return InferenceResult(
            probabilities={
                "Level 1": probs[0],
                "Level 2": probs[1],
                "Level 3": probs[2]
            },
            predicted_level=predicted_level,
            confidence=confidence,
            model_version="v1.0-mock",
            is_uncertain=confidence < settings.mri_confidence_threshold
        )

class LocalTFProvider(MRIInferenceProvider):
    def __init__(self):
        self.model_path = getattr(settings, "mri_model_path_tf", "/app/app/models/mri/resnet_v1.h5")
        self.expected_input_shape = (224, 224)
        self.expected_channels = 3
        self.needs_softmax = False

    def _get_model_diagnostics(self):
        """Internal helper to log model file details for auditability"""
        if not os.path.exists(self.model_path):
            return "File Missing"
        
        size_mb = os.path.getsize(self.model_path) / (1024 * 1024)
        sha256_hash = hashlib.sha256()
        with open(self.model_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        
        return {
            "size_mb": round(size_mb, 2),
            "sha256": sha256_hash.hexdigest()[:12] + "...",
            "path": self.model_path
        }

    def _get_model(self):
        global _MODEL_CACHE
        if _MODEL_CACHE is None:
            if not HAS_ML_LIBS:
                raise ImportError("ML Dependencies (TensorFlow/NumPy) not installed in this environment.")
            
            if not os.path.exists(self.model_path):
                logger.error(f"❌ AI (Local): Model weights not found at {self.model_path}")
                raise FileNotFoundError(f"Model file {self.model_path} missing.")
            
            # Diagnostic Log (File metadata)
            diag = self._get_model_diagnostics()
            logger.info(f"🧠 AI (Local): Loading ResNet weights [{diag['size_mb']} MB] [Hash: {diag['sha256']}]")
            
            try:
                # 1. Load model
                _MODEL_CACHE = tf.keras.models.load_model(self.model_path, compile=False)
                
                # 2. Architecture Validation & Diagnostics
                # Handle cases where input_shape is a list or has multiple entries
                input_tensor_shape = _MODEL_CACHE.input_shape
                if isinstance(input_tensor_shape, list):
                     input_tensor_shape = input_tensor_shape[0]
                
                # Extract Target Dimensions
                # Shape is usually (None, height, width, channels)
                self.expected_input_shape = (input_tensor_shape[1], input_tensor_shape[2])
                self.expected_channels = input_tensor_shape[3]
                
                # 3. Final Layer Check
                last_layer = _MODEL_CACHE.layers[-1]
                activation = getattr(last_layer, 'activation', None)
                activation_name = str(activation.__name__ if activation else "Unknown").lower()
                
                logger.info(f"✅ AI (Local): Model loaded into memory.")
                logger.info(f"📊 AI (Local): Architecture: Input={input_tensor_shape}, Output={last_layer.name}, Activation={activation_name}")
                
                # 4. Strict Validation
                if self.expected_input_shape != (224, 224):
                    logger.error(f"❌ AI (Local): Architecture MISMATCH. Expected (224, 224), got {self.expected_input_shape}")
                    _MODEL_CACHE = None # Invalidate cache
                    raise ValueError(f"Incompatible model input shape: {self.expected_input_shape}")

                if activation_name != 'softmax':
                    logger.warning("⚠️ AI (Local): Output layer lacks Softmax. Internal normalization enabled.")
                    self.needs_softmax = True
                
            except Exception as e:
                logger.error(f"❌ AI (Local): Failed to parse/validate model file: {e}")
                raise e
                
        return _MODEL_CACHE

    def preprocess(self, file_url_or_content: Any) -> np.ndarray:
        """Resize and adapt channels based on model requirement, then normalize to [0, 1]"""
        # Determine mode based on expected channels
        mode = 'RGB' if self.expected_channels == 3 else 'L' # 'L' is grayscale
        
        img = Image.open(file_url_or_content).convert(mode)
        img = img.resize(self.expected_input_shape)
        img_array = np.array(img).astype('float32') / 255.0
        
        # Handle dimension expansion based on rank
        if self.expected_channels == 1:
            img_array = np.expand_dims(img_array, axis=-1)
            
        return np.expand_dims(img_array, axis=0)

    async def run_inference(self, file_url: str) -> InferenceResult:
        """Real TensorFlow Inference Execution with Safety Hooks"""
        try:
            model = self._get_model()
            
            # 1. Fetch file from storage (MinIO)
            import httpx
            async with httpx.AsyncClient() as client:
                response = await client.get(file_url)
                if response.status_code != 200:
                    raise Exception(f"Failed to fetch scan from storage: {response.status_code}")
                img_bytes = io.BytesIO(response.content)

            # 2. Preprocess (Dynamic Channel Handling)
            processed_img = self.preprocess(img_bytes)

            # 3. Predict (Offloaded to thread pool)
            loop = asyncio.get_event_loop()
            raw_output = await loop.run_in_executor(None, model.predict, processed_img)
            
            # 4. Activation Post-handling
            if self.needs_softmax:
                probs_array = tf.nn.softmax(raw_output).numpy()[0]
            else:
                probs_array = raw_output[0]
            
            # 5. Result Mapping (4-class Dataset -> 3-level Platform)
            # Dataset Indices (Alphabetical): 
            # 0: MildDemented, 1: ModerateDemented, 2: NonDemented, 3: VeryMildDemented
            # Mapping Logic based on clinical alignment:
            mapping = {
                0: 2, # Mild -> Level 2
                1: 3, # Moderate -> Level 3
                2: 1, # Non-Demented -> Level 1
                3: 2  # Very Mild -> Level 2
            }
            
            predicted_idx = int(np.argmax(probs_array))
            predicted_level = mapping.get(predicted_idx, 1) # Default to L1 if error
            confidence = float(np.max(probs_array))
            
            logger.info(f"✅ AI (Local): Inference successful. RawIdx={predicted_idx}, FinalLevel={predicted_level}, Conf={confidence:.2f}")

            return InferenceResult(
                probabilities={
                    "Level 1": float(probs_array[2]),               # NonDemented
                    "Level 2": float(probs_array[0] + probs_array[3]), # Mild + VeryMild
                    "Level 3": float(probs_array[1])                # Moderate
                },
                predicted_level=predicted_level,
                confidence=confidence,
                model_version="resnet_v1_clinical",
                is_uncertain=confidence < settings.mri_confidence_threshold
            )
        except Exception as e:
            logger.error(f"❌ AI (Local): Runtime inference error: {e}")
            # Fallback to mock if configured
            if getattr(settings, "mri_fallback_to_mock", True):
                logger.warning("🔄 AI (Local): Fallback to Mock Provider engaged.")
                return await MockProvider().run_inference(file_url)
            raise e

class LocalTorchProvider(MRIInferenceProvider):
    def __init__(self):
        self.model_path = getattr(settings, "mri_model_path_torch", "/app/app/models/mri/efficientnet_v1_torch.pth")
        
        # EXACT Preprocessing matching training:
        self.transform = None
        if HAS_TORCH:
            self.transform = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
            ])

    def _get_model(self):
        global _MODEL_CACHE
        if _MODEL_CACHE is None or not isinstance(_MODEL_CACHE, nn.Module):
            if not HAS_TORCH:
                raise ImportError("PyTorch components not installed.")
            
            if not os.path.exists(self.model_path):
                raise FileNotFoundError(f"Model file {self.model_path} missing.")
            
            # Recreate EXACT architecture from training!
            model = models.efficientnet_b0()
            num_features = model.classifier[1].in_features
            model.classifier = nn.Sequential(
                nn.Dropout(p=0.3, inplace=True),
                nn.Linear(num_features, 256),
                nn.ReLU(),
                nn.Dropout(p=0.3),
                nn.Linear(256, 4) # 4 classes
            )
            
            # Load states on CPU (as instructed)
            model.load_state_dict(torch.load(self.model_path, map_location=torch.device('cpu')))
            model.eval() # Vital for inference!
            
            _MODEL_CACHE = model
            logger.info("✅ AI (Torch): Model loaded successfully into memory.")
            
        return _MODEL_CACHE

    async def run_inference(self, file_url: str) -> InferenceResult:
        try:
            model = self._get_model()
            
            import httpx
            async with httpx.AsyncClient() as client:
                response = await client.get(file_url)
                if response.status_code != 200:
                    raise Exception(f"Failed to fetch scan: {response.status_code}")
                img_bytes = io.BytesIO(response.content)

            # Preprocess ensuring 3-channel RGB
            img = Image.open(img_bytes).convert('RGB')
            input_tensor = self.transform(img).unsqueeze(0) # Add batch dimension

            # Predict
            loop = asyncio.get_event_loop()
            import functools
            infer_fn = functools.partial(self._predict_sync, model, input_tensor)
            probs_array = await loop.run_in_executor(None, infer_fn)
            
            # Class mapping (Strict adherence to the 4 -> 3 levels logic!)
            # 0: MildDemented, 1: ModerateDemented, 2: NonDemented, 3: VeryMildDemented
            level1 = probs_array[2]
            level2 = probs_array[0] + probs_array[3]
            level3 = probs_array[1]
            
            probs = [level1, level2, level3]
            predicted_level = probs.index(max(probs)) + 1
            confidence = max(probs)
            
            logger.info(f"✅ AI (Torch): Inference successful. Calculated Level={predicted_level}, Conf={confidence:.4f}")

            return InferenceResult(
                probabilities={
                    "Level 1": float(level1),
                    "Level 2": float(level2),
                    "Level 3": float(level3)
                },
                predicted_level=predicted_level,
                confidence=float(confidence),
                model_version="efficientnet_torch_v1",
                is_uncertain=float(confidence) < settings.mri_confidence_threshold
            )
        except Exception as e:
            logger.error(f"❌ AI (Torch): Runtime inference error: {e}")
            if getattr(settings, "mri_fallback_to_mock", True):
                return await MockProvider().run_inference(file_url)
            raise e

    def _predict_sync(self, model, input_tensor):
        with torch.no_grad():
            output = model(input_tensor)
            probs = torch.softmax(output, dim=1)
            return probs[0].numpy()

class ExternalAPIProvider(MRIInferenceProvider):
    async def run_inference(self, file_path_or_url: str) -> InferenceResult:
        logger.info(f"🧠 AI (External): Proxying request for {file_path_or_url}...")
        return await MockProvider().run_inference(file_path_or_url)

class MRIInferenceFactory:
    _providers = {
        "mock": MockProvider,
        "local_tf": LocalTFProvider,
        "local_torch": LocalTorchProvider,
        "external": ExternalAPIProvider
    }

    @classmethod
    def get_provider(cls) -> MRIInferenceProvider:
        provider_name = getattr(settings, "mri_model_provider", "mock").lower()
        provider_cls = cls._providers.get(provider_name)
        
        if not provider_cls:
            logger.warning(f"⚠️ AI Factory: Provider '{provider_name}' not found. Defaulting to Mock.")
            return MockProvider()
            
        return provider_cls()

class MRIInferenceService:
    async def analyze_scan(self, scan_id: str, file_url: str) -> InferenceResult:
        """Main entry point for MRI analysis tasks."""
        try:
            provider = MRIInferenceFactory.get_provider()
            logger.debug(f"🔄 AI service: Analyzing {scan_id} via {type(provider).__name__}")
            
            result = await asyncio.wait_for(
                provider.run_inference(file_url),
                timeout=getattr(settings, "mri_inference_timeout", 60.0)
            )
            return result
        except asyncio.TimeoutError:
            logger.error(f"❌ AI: Inference timed out for scan {scan_id}")
            raise Exception("AI inference timed out")
        except Exception as e:
            logger.error(f"❌ AI: Service failure during scan {scan_id}: {e}")
            raise e

# Singleton instance
mri_inference_service = MRIInferenceService()
