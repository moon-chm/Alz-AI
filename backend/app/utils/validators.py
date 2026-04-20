import re

def validate_indian_phone(phone: str) -> bool:
    pattern = r'^(\+91)?[6-9]\d{9}$'
    return bool(re.match(pattern, phone.strip()))

def validate_nmc_number(nmc: str) -> bool:
    pattern = r'^NMC-[A-Z0-9]{5}$'
    return bool(re.match(pattern, nmc.upper().strip()))

def validate_alz_id(alz_id: str) -> bool:
    pattern = r'^ALZ-[A-Z]{2}-\d{4}-\d{5}$'
    return bool(re.match(pattern, alz_id.strip()))

def validate_email(email: str) -> bool:
    pattern = r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email.strip()))
