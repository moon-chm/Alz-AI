from fastapi import APIRouter, Depends, HTTPException, status, Request, Response
from sqlalchemy.orm import Session
from app.database.postgres import get_db
from app.models.user import User, RoleEnum
from app.models.patient import Patient
from app.schemas.auth import (
    DoctorRegister, CaretakerRegister, LoginRequest, 
    TokenResponse, RefreshRequest, OTPSendRequest, OTPVerifyRequest, 
    UserResponse, UnifiedOTPRequest, UnifiedLoginRequest, CaretakerRegisterResponse
)
from app.utils.password import hash_password, verify_password
from app.utils.jwt import create_access_token, create_refresh_token, decode_token, blacklist_token, get_current_user
from app.utils.validators import validate_indian_phone, validate_nmc_number
from app.services import otp_service
from datetime import timedelta, datetime
import uuid
import logging
from app.services import audit_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["auth"])

@router.post("/register/doctor", response_model=UserResponse, status_code=201)
async def register_doctor(data: DoctorRegister, db: Session = Depends(get_db)):
    from app.config import settings
    from app.models.user import UserStatus
    
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(400, "Email already registered")
    if not validate_indian_phone(data.phone):
        raise HTTPException(400, "Invalid Indian phone number")
    if not validate_nmc_number(data.nmc_number):
        raise HTTPException(400, "Invalid NMC number format (e.g. NMC-AB123)")
        
    # Determine initial status based on System Mode
    initial_status = UserStatus.pending
    if settings.system_mode == "DEMO" and settings.doctor_auto_activate:
        initial_status = UserStatus.active
        
    user = User(
        id=uuid.uuid4(),
        email=data.email,
        password_hash=hash_password(data.password),
        role=RoleEnum.doctor,
        full_name=data.full_name,
        phone=data.phone,
        nmc_number=data.nmc_number,
        specialization=getattr(data, "specialization", None),
        hospital_name=getattr(data, "hospital_name", None),
        status=initial_status
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/register/caretaker", status_code=202)
async def register_caretaker(data: CaretakerRegister, db: Session = Depends(get_db)):
    from app.database.redis_client import redis_client
    import json
    
    # 1. Basic User check
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(400, "Email already registered")
        
    # 2. Resolve Patient & Get Trusted Phone (Target)
    patient = db.query(Patient).filter(Patient.patient_unique_id == data.patient_unique_id).first()
    if not patient:
        raise HTTPException(404, "Invalid Patient ID")
        
    target_phone = patient.trusted_phone
    caretaker_phone = data.phone
    
    # 3. Stage Registration in Redis (Keyed by Caretaker Phone)
    # PATCH 1: Identity binding contract
    reg_key = f"pending_reg:{caretaker_phone}"
    payload = {
        "email": data.email,
        "password_hash": hash_password(data.password),
        "full_name": data.full_name,
        "phone": caretaker_phone,
        "patient_id": str(patient.id),
        "target_phone": target_phone # MUST BE STORED FOR VERIFICATION
    }
    
    if redis_client:
        redis_client.setex(reg_key, 1800, json.dumps(payload)) # 30 min TTL
        
    # 4. Trigger OTP to Target Phone (Family)
    await otp_service.generate_otp(target_phone)
    
    # PATCH 3: Response contract
    return {
        "success": True,
        "message": "Verification code sent to patient's trusted family number",
        "recipient_phone_masked": f"+91******{target_phone[-2:]}",
        "verification_key": caretaker_phone # Frontend MUST use this for verify step
    }

@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, response: Response, db: Session = Depends(get_db)):
    from app.models.user import UserStatus
    
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid credentials")
        
    # Check status for doctors
    if user.role == RoleEnum.doctor and user.status != UserStatus.active:
        detail = "Your medical account is pending verification." if user.status == UserStatus.pending else "Your account has been rejected."
        raise HTTPException(status.HTTP_403_FORBIDDEN, detail)
        
    access_token = create_access_token(data={"sub": str(user.id), "role": user.role.value, "email": user.email})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    response.set_cookie(key="access_token", value=access_token, httponly=True, secure=True, samesite="lax")
    response.set_cookie(key="refresh_token", value=refresh_token, httponly=True, secure=True, samesite="lax")
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        role=user.role.value,
        user_id=str(user.id)
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: Request, response: Response, data: RefreshRequest = None, db: Session = Depends(get_db)):
    token = request.cookies.get("refresh_token")
    if data and data.refresh_token:
        token = data.refresh_token
        
    if not token:
        raise HTTPException(status_code=401, detail="Refresh token missing")
        
    payload = decode_token(token)
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid token type")
        
    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
        
    new_access = create_access_token(data={"sub": str(user.id), "role": user.role.value, "email": user.email})
    new_refresh = create_refresh_token(data={"sub": str(user.id)})
    
    blacklist_token(token)
    
    response.set_cookie(key="access_token", value=new_access, httponly=True, secure=True, samesite="lax")
    response.set_cookie(key="refresh_token", value=new_refresh, httponly=True, secure=True, samesite="lax")
    
    return TokenResponse(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
        role=user.role.value,
        user_id=str(user.id)
    )

@router.post("/logout")
async def logout(request: Request, response: Response):
    access_token = request.cookies.get("access_token")
    refresh_token = request.cookies.get("refresh_token")
    
    if access_token:
        blacklist_token(access_token)
    if refresh_token:
        blacklist_token(refresh_token)
        
    response.delete_cookie("access_token")
    response.delete_cookie("refresh_token")
    return {"message": "Logged out successfully"}

@router.post("/send-otp")
async def send_otp(data: OTPSendRequest):
    if not validate_indian_phone(data.phone):
        raise HTTPException(400, "Invalid phone number")
    await otp_service.generate_otp(data.phone)
    return {"message": "OTP sent successfully", "phone": data.phone}

@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(data: OTPVerifyRequest, response: Response, db: Session = Depends(get_db)):
    from app.database.redis_client import redis_client
    from app.models.patient import CaretakerPatient
    from app.models.user import UserStatus
    import json
    
    # 1. Load Staging Data (Identity contract Patch 2)
    # The 'phone' in the request is the caretaker's phone (the verification_key)
    reg_key = f"pending_reg:{data.phone}"
    pending_reg = None
    if redis_client:
        raw = redis_client.get(reg_key)
        if raw: pending_reg = json.loads(raw)
        
    if not pending_reg:
        # Check if it was an existing user just activating (limited fallback)
        user = db.query(User).filter(User.phone == data.phone).first()
        if not user:
            # PATCH 5: No fallback login for unknown identities
            audit_service.log_otp_event(db, data.phone, "verify_fail_no_staging", False)
            raise HTTPException(404, "Registration staging expired or invalid key")
        
        # Identity to verify OTP against is their own phone if existing
        target_phone = data.phone
    else:
        # Identity to verify OTP against is the family phone stored in staging
        target_phone = pending_reg["target_phone"]

    # 2. Verify OTP against the TARGET phone (Identity Contract Patch 2)
    if not otp_service.verify_otp(target_phone, data.otp):
        audit_service.log_otp_event(db, target_phone, "verify_fail", False)
        # PATCH 5: Explicit error, no fallback login
        raise HTTPException(400, "Invalid or expired OTP")
    
    # 3. Finalize Atomic Registration (Patch 6)
    user = None
    if pending_reg:
        try:
            user = User(
                id=uuid.uuid4(),
                email=pending_reg["email"],
                password_hash=pending_reg["password_hash"],
                role=RoleEnum.caretaker, # STRICT ROLE
                full_name=pending_reg["full_name"],
                phone=pending_reg["phone"], 
                status=UserStatus.active
            )
            db.add(user)
            db.flush() 
            
            link = CaretakerPatient(
                caretaker_id=user.id,
                patient_id=uuid.UUID(pending_reg["patient_id"]),
                relationship_type="primary",
                is_primary=True,
                verified_at=datetime.utcnow()
            )
            db.add(link)
            db.commit()
            db.refresh(user)
            
            # Clean up staging (Patch 2)
            if redis_client: redis_client.delete(reg_key)
            audit_service.log_otp_event(db, target_phone, "verify_success_reg", True)
            
        except Exception as e:
            db.rollback()
            # PATCH 2: Ensure staging is cleared on DB failure to prevent stale states
            if redis_client: redis_client.delete(reg_key)
            logger.error(f"Atomic registration failure: {e}")
            raise HTTPException(500, "Failed to finalize registration")
    else:
        # Case for existing users activating
        user = db.query(User).filter(User.phone == data.phone).first()
        user.status = UserStatus.active
        db.commit()
        audit_service.log_otp_event(db, target_phone, "verify_success_login", True)
    
    # 4. Create Session Tokens (Patch 6: Role Consistency)
    access_token = create_access_token(data={"sub": str(user.id), "role": user.role.value, "email": user.email})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    response.set_cookie(key="access_token", value=access_token, httponly=True, secure=True, samesite="lax")
    response.set_cookie(key="refresh_token", value=refresh_token, httponly=True, secure=True, samesite="lax")
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer", 
        role=user.role.value,
        user_id=str(user.id)
    )

@router.post("/request-otp")
async def request_otp(data: UnifiedOTPRequest, db: Session = Depends(get_db)):
    import os
    from app.config import settings
    print(f"DEBUG: request_otp hit! Role: {data.role}, ID: {data.identifier}")
    is_dev = os.getenv("ENV") == "dev" or os.getenv("DEBUG") == "true" or settings.system_mode == "DEMO"
    print(f"DEBUG: is_dev evaluated to {is_dev}")
    
    phone = None
    
    if data.role == "patient":
        patient = db.query(Patient).filter(Patient.patient_unique_id == data.identifier).first()
        if not patient and not is_dev:
            raise HTTPException(404, "Patient ID not found")
        phone = patient.trusted_phone if patient else data.identifier
    elif data.role == "caretaker":
        user = db.query(User).filter(User.phone == data.identifier, User.role == RoleEnum.caretaker).first()
        if not user and not is_dev:
            raise HTTPException(404, "Caretaker phone not registered")
        phone = user.phone if user else data.identifier
    else:
        raise HTTPException(400, "Invalid role specified")

    if not phone and not is_dev:
        raise HTTPException(400, "Could not resolve phone number for identifier")
        
    try:
        otp = await otp_service.generate_otp(phone)
        return {"message": "OTP sent successfully", "recipient_preview": f"******{phone[-4:]}"}
    except Exception as e:
        if is_dev:
            return {"message": "OTP sent successfully (Fallback)", "recipient_preview": f"******{phone[-4:]}", "is_mock": True}
        raise HTTPException(500, "Failed to send OTP due to service error")

@router.post("/login/otp", response_model=TokenResponse)
async def login_otp(data: UnifiedLoginRequest, response: Response, db: Session = Depends(get_db)):
    import os
    from app.config import settings
    is_dev = os.getenv("ENV") == "dev" or os.getenv("DEBUG") == "true" or settings.system_mode == "DEMO"
    
    phone = data.identifier
    user_to_auth = None
    patient_id_out = None
    
    # 1. Resolve identifier to phone
    if data.role == "patient":
        patient = db.query(Patient).filter(Patient.patient_unique_id == data.identifier).first()
        if patient:
            phone = patient.trusted_phone
            patient_id_out = str(patient.id)
            from app.models.patient import CaretakerPatient
            link = db.query(CaretakerPatient).filter(CaretakerPatient.patient_id == patient.id, CaretakerPatient.is_primary == True).first()
            if link:
                user_to_auth = db.query(User).filter(User.id == link.caretaker_id).first()
    else:
        user_to_auth = db.query(User).filter(User.phone == data.identifier, User.role == RoleEnum.caretaker).first()
        if user_to_auth:
            phone = user_to_auth.phone

    # 2. Verify OTP
    is_mock = False
    if is_dev and data.otp == "000000":
        is_mock = True
    else:
        if not otp_service.verify_otp(phone, data.otp):
            raise HTTPException(400, "Invalid or expired OTP")
            
    # Mock fallback auto-success
    if is_mock and not user_to_auth:
        import uuid
        dummy_user_id = str(uuid.uuid4())
        return TokenResponse(
            access_token="dev_token",
            refresh_token="dev_token",
            token_type="bearer",
            role=data.role,
            user_id=dummy_user_id,
            patient_id=f"test_patient_{data.identifier}",
            is_mock=True
        )

    if not user_to_auth:
        raise HTTPException(404, "No linked caretaker found for this patient")

    # 3. Create tokens
    access_token = create_access_token(data={"sub": str(user_to_auth.id), "role": user_to_auth.role.value, "email": user_to_auth.email})
    refresh_token = create_refresh_token(data={"sub": str(user_to_auth.id)})
    
    response.set_cookie(key="access_token", value=access_token, httponly=True, secure=True, samesite="lax")
    response.set_cookie(key="refresh_token", value=refresh_token, httponly=True, secure=True, samesite="lax")
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        role=user_to_auth.role.value,
        user_id=str(user_to_auth.id),
        patient_id=patient_id_out,
        is_mock=is_mock
    )

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
