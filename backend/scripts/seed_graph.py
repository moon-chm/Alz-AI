import os
import psycopg2
from neo4j import GraphDatabase
from dotenv import load_dotenv
import logging
from datetime import datetime, date
import uuid

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

load_dotenv()

# DB Configurations
POSTGRES_URL = os.getenv("POSTGRES_URL", "").replace("alzai-db", "localhost")
NEO4J_URI = os.getenv("NEO4J_URI", "").replace("neo4j", "localhost")
NEO4J_USER = os.getenv("NEO4J_USERNAME", "neo4j")
NEO4J_PWD = os.getenv("NEO4J_PASSWORD")

def seed():
    pg_conn = None
    neo4j_driver = None
    
    try:
        # 1. Connect to both databases
        logger.info("🔗 Connecting to databases...")
        pg_conn = psycopg2.connect(POSTGRES_URL)
        neo4j_driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PWD))
        
        pg_cur = pg_conn.cursor()
        
        # 2. Fetch Patients from Postgres
        pg_cur.execute("SELECT id, full_name, language, level FROM patients")
        patients = pg_cur.fetchall()
        
        if not patients:
            logger.error("❌ No patients found in Postgres. Seed failed.")
            return

        with neo4j_driver.session() as session:
            for p_id, p_name, p_lang, p_level in patients:
                logger.info(f"🌱 Seeding graph for Patient: {p_name} ({p_id})")
                
                # A. Create/Merge Patient Node
                session.run("""
                    MERGE (p:Patient {id: $id})
                    SET p.name = $name, 
                        p.language = $lang, 
                        p.level = $level
                """, id=p_id, name=p_name, lang=p_lang or 'Hindi', level=p_level or 1)

                if "Akay" in p_name:
                    family = [
                        {"name": "Arjun Kohali", "rel": "Son", "phone": "+91 9876543210"},
                        {"name": "Priya Kohali", "rel": "Daughter", "phone": "+91 9876543211"}
                    ]
                    memories = [
                        {"content": "Lived in a beautiful wooden house in Shimla for 20 years.", "cat": "Personal"},
                        {"content": "Worked as a Senior Engineer at the Indian Railways.", "cat": "Career"}
                    ]
                    habits = [
                        {"desc": "Drinking hot ginger tea at 8:00 AM", "time": "Morning"},
                        {"desc": "Reading the newspaper on the balcony", "time": "Morning"}
                    ]
                else: # John Doe
                    family = [
                        {"name": "Jane Doe", "rel": "Spouse", "phone": "+1 555-0199"},
                        {"name": "Sarah Doe", "rel": "Daughter", "phone": "+1 555-0198"}
                    ]
                    memories = [
                        {"content": "Spent every summer at the lakehouse in Maine.", "cat": "Family"},
                        {"content": "Won the state chess championship in 1985.", "cat": "Personal"}
                    ]
                    habits = [
                        {"desc": "Watching the evening news", "time": "Evening"},
                        {"desc": "Short walk in the garden after lunch", "time": "Afternoon"}
                    ]

                # B. Merge Family Members and Relationships
                for f in family:
                    f_id = str(uuid.uuid4())
                    session.run("""
                        MATCH (p:Patient {id: $p_id})
                        MERGE (f:FamilyMember {name: $name})
                        SET f.id = $id, f.relationship = $rel, f.phone = $phone
                        MERGE (p)-[:HAS_FAMILY]->(f)
                    """, p_id=p_id, name=f["name"], id=f_id, rel=f["rel"], phone=f["phone"])
                    
                    session.run("""
                        MATCH (p:Patient {id: $p_id})
                        MATCH (f:FamilyMember {name: $name})
                        MERGE (f)-[v:VISITING_ON]->(p)
                        SET v.date = date($visit_date), v.time = "10:00"
                    """, p_id=p_id, name=f["name"], visit_date=date.today().isoformat())

                # C. Merge Memories
                for m in memories:
                    m_id = str(uuid.uuid4())
                    session.run("""
                        MATCH (p:Patient {id: $p_id})
                        MERGE (m:Memory {content: $content})
                        SET m.id = $id, m.category = $cat, m.date_added = $date
                        MERGE (p)-[:HAS_MEMORY]->(m)
                    """, p_id=p_id, content=m["content"], id=m_id, cat=m["cat"], date=datetime.now().isoformat())

                # D. Merge Habits
                for h in habits:
                    session.run("""
                        MATCH (p:Patient {id: $p_id})
                        MERGE (h:Habit {description: $desc})
                        SET h.time_of_day = $time
                        MERGE (p)-[:HAS_HABIT]->(h)
                    """, p_id=p_id, desc=h["desc"], time=h["time"])

        logger.info("✅ Graph Seeding Complete!")
        
        # 3. Final Validation Summary
        with neo4j_driver.session() as session:
            node_count = session.run("MATCH (n) RETURN count(n)").single()[0]
            rel_count = session.run("MATCH ()-[r]->() RETURN count(r)").single()[0]
            logger.info(f"📊 SUMMARY: {node_count} nodes and {rel_count} relationships in local graph.")

    except Exception as e:
        logger.error(f"❌ SEEDING FAILED: {e}")
    finally:
        if pg_conn: pg_conn.close()
        if neo4j_driver: neo4j_driver.close()

if __name__ == "__main__":
    seed()
