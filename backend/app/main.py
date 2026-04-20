from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth, doctor, caretaker, patient
from app.routes import saathi, medications, appointments
from app.routes import alerts, media, memory, analytics
from app.routes import reports, websocket, health
from app.database.neo4j import verify_connection

app = FastAPI(
    title="Alz-AI API",
    description="Alzheimer's Care Platform API",
    version="1.0.0",
    root_path="/api"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1"
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(auth.router, prefix="/auth")
app.include_router(doctor.router, prefix="/doctor")
app.include_router(caretaker.router, prefix="/caretaker")
app.include_router(patient.router, prefix="/patient")
app.include_router(saathi.router, prefix="/saathi")
app.include_router(medications.router, prefix="/medications")
app.include_router(appointments.router, prefix="/appointments")
app.include_router(alerts.router, prefix="/alerts")
app.include_router(media.router, prefix="/media")
app.include_router(memory.router, prefix="/memory")
app.include_router(analytics.router, prefix="/analytics")
app.include_router(reports.router, prefix="/reports")
app.include_router(websocket.router)
app.include_router(health.router)

from app.database.postgres import engine, Base
from app import models as _models  # Ensures all models are registered without shadowing main `app` obj
from sqlalchemy.exc import OperationalError
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import asyncio

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "success": False, 
            "data": None,
            "message": "Internal Server Error", 
            "error": str(exc)
        },
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        field = ".".join(str(loc) for loc in err.get("loc", []))
        msg = err.get("msg", "Invalid value")
        errors.append(f"{field}: {msg}")
    
    error_msg = "; ".join(errors)
    print(f"❌ VALIDATION ERROR: {error_msg}")  # Log to console for debugging
    return JSONResponse(
        status_code=422,
        content={
            "success": False, 
            "data": None,
            "message": "Data validation failed", 
            "error": error_msg
        },
    )


@app.on_event("startup")
async def startup():
    # Automatically create PostgreSQL tables if they don't exist, with retry for Neon.tech cold starts
    for attempt in range(5):
        try:
            Base.metadata.create_all(bind=engine)
            break
        except OperationalError:
            if attempt == 4:
                raise
            await asyncio.sleep(2)
    verify_connection()

@app.on_event("shutdown")
async def shutdown():
    from app.database.neo4j import close_driver
    close_driver()