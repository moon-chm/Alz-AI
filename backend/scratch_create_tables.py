from app.database.postgres import engine, Base
from app.models import AdherenceLog # Import to register

print("Creating tables...")
Base.metadata.create_all(bind=engine)
print("Done.")
