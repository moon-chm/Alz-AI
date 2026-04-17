<div align="center">
  <img src="https://img.shields.io/badge/Status-Active-success.svg?style=for-the-badge" alt="Status" />
  <img src="https://img.shields.io/badge/Platform-Mobile%20%7C%20Web-blue.svg?style=for-the-badge" alt="Platform" />
  <img src="https://img.shields.io/badge/Backend-FastAPI-009688.svg?style=for-the-badge" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Frontend-Flutter%20%7C%20React-02569B.svg?style=for-the-badge" alt="Flutter" />
</div>

<br />

<div align="center">
  <h1>🧠 Alz-AI Care Platform</h1>
  <p>An intelligent, highly-scalable ecosystem designed to support patients facing Alzheimer's and cognitive decline, along with their caretakers and medical professionals.</p>
</div>

---

## ✨ System Architecture 

Built for modern scalability and resilient performance:

- **Database Backbone**: PostgreSQL (Neon.tech) for relational integrity, Neo4j (AuraDB) for advanced graph-based relationship tracking.
- **Mobile Experience**: Flutter APK built natively for smooth on-device interactions.
- **Containerized Core**: Dockerized ecosystem powering the Backend (FastAPI), Web Frontend (React), Caching (Redis), and Reverse Proxy (Nginx).
- **Log Management**: Natively rotated locally for 7 days via Docker bounds; Papertrail cloud sync scalable up to 30 days.

---

## 🚀 One-Click Deploy

Spin up the entire internal infrastructure in minutes using Docker Compose.

```bash
# Step 1 — Clone the repository
git clone https://github.com/moon-chm/Alz-AI.git
cd alz-ai

# Step 2 — Environment Setup
cp .env.example .env
nano .env # Fill in your required keys

# Step 3 — Build and Start Services
docker-compose up --build
```

### 📋 Live Services Overview:
- **Backend API**: `http://localhost:8000`
- **Frontend Panel**: `http://localhost:3000`
- **API Documentation**: `http://localhost:8000/docs`
- **Redis Cache**: `localhost:6379`

### 📦 Database Migrations
Always ensure the database schema is fully aligned before starting the backend tasks.
```bash
docker-compose exec backend alembic upgrade head
```

### 📱 Flutter APK Delivery
To build and deploy the mobile app directly to Android hardware:
```bash
cd mobile
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk

adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📈 Scalability Roadmap (V2 Triggers)

We adhere strictly to data-driven service decomposition. Premature scaling is prohibited.

1. **SAATHI Service**: Extract when audio p95 tracking latency exceeds `> 3s`.
2. **Analytics Service**: Extract when background queue arrays detect API throttling `> 50%` CPU utilization persistently during nightly jobs.
3. **Notification Service**: Extract when the SLA `< 30s` Twilio boundary is natively missed over `3x` within a collective week span.
4. **Media Service**: Extract upon aggregate Cloudinary uploads crossing a concurrent load of `10GB/hour`.

---

# Alz-AI
