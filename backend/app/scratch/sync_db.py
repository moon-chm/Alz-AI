import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database.postgres import engine, Base
import app.models # Ensure all models are imported for Base.metadata

def create_tables():
    print("Creating all tables in Postgres...")
    Base.metadata.create_all(bind=engine)
    print("Done!")

if __name__ == "__main__":
    create_tables()
