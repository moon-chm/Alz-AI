from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

DATABASE_URL = 'postgresql://alzai:alzai_secure_password@localhost:5432/alzai'
engine = create_engine(DATABASE_URL)
db = sessionmaker(bind=engine)()

db.execute(text("UPDATE users SET status = 'active' WHERE role = 'doctor';"))
db.commit()
print('Doctors activated!')
