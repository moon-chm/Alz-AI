FROM python:3.11-bookworm

WORKDIR /app

# ✅ Stable system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    ca-certificates \
    openssl \
    build-essential \
    git \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ✅ SSL fix
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

COPY requirements.txt .

# ✅ Python setup
RUN pip install --upgrade pip "setuptools<71" wheel

# ✅ TensorFlow (required for DeepFace)
RUN pip install --no-cache-dir tensorflow==2.15.0
# ✅ Install dependencies (better layer caching)
RUN pip install --no-cache-dir torch==2.1.1 --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir --no-build-isolation openai-whisper==20240930 && \
    pip install --no-cache-dir -r requirements.txt structlog

# ✅ Whisper model download (with retry)
RUN python - <<EOF
import whisper, time

for i in range(5):
    try:
        whisper.load_model("base")
        print("✅ Model downloaded successfully")
        break
    except Exception as e:
        print(f"Retry {i+1}/5 failed:", e)
        time.sleep(5)
else:
    raise RuntimeError("❌ Failed to download Whisper model")
EOF

COPY . .

# ✅ Healthcheck handled by docker-compose

# ✅ Start server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]