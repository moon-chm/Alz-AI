import sys
import os

# Add the backend directory to the path so we can import from app
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database.postgres import SessionLocal
from app.models.user import User
from app.utils.password import hash_password

def reset():
    db = SessionLocal()
    try:
        users = [
            "test-doctor@example.com",
            "test-caretaker@example.com"
        ]
        
        for email in users:
            user = db.query(User).filter(User.email == email).first()
            if user:
                print(f"Resetting password for {email}")
                user.password_hash = hash_password("alzai_secure_password")
            else:
                print(f"User {email} not found.")
        
        db.commit()
        print("Passwords reset successfully.")
        
    except Exception as e:
        db.rollback()
        print(f"Reset failed: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    reset()
