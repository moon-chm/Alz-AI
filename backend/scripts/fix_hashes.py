import sys
import os

# Add the parent directory to sys.path so we can import 'app'
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database.postgres import SessionLocal
from app.models.user import User
from app.utils.password import hash_password

def fix_caretaker_hash():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == "test-caretaker@example.com").first()
        if user:
            print(f"Found user: {user.email}. Role: {user.role}")
            new_hash = hash_password("password")
            user.password_hash = new_hash
            db.commit()
            print("✅ Password hash updated successfully.")
        else:
            print("❌ User 'test-caretaker@example.com' not found.")
            
        # Also fix any other test accounts that might be corrupted
        doctor = db.query(User).filter(User.email == "test-doctor@example.com").first()
        if doctor:
            print(f"Found user: {doctor.email}. Role: {doctor.role}")
            doctor.password_hash = hash_password("password")
            db.commit()
            print("✅ Doctor password hash updated successfully.")
            
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix_caretaker_hash()
