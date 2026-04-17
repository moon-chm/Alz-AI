@echo off
echo =======================================================
echo          🚀 ALZ-AI SYSTEM LAUNCHER (One-Click)
echo =======================================================
echo.

echo [1/3] Starting Cloud Architecture (Postgres, Redis, FastAPI, React)...
docker-compose --env-file .env up --build -d

echo.
echo ✅ Cloud architecture is running in the background!
echo - API Docs: http://localhost:8000/docs
echo - Caretaker Dashboard: http://localhost:3000
echo.

echo [2/3] Checking connected Android devices/emulators...
cd mobile
call flutter devices

echo.
echo [3/3] Launching Patient Mobile Engine...
echo (If multiple devices exist, you may need to specify one, otherwise it defaults)
call flutter run

echo.
echo =======================================================
echo ✅ System termination executed.
echo To shut down background cloud services later, run:
echo docker-compose down
echo =======================================================
pause
