import os
import psycopg2
from psycopg2 import extras
from dotenv import load_dotenv
import sys

# Load environment variables
load_dotenv()

# Cloud Source (Neon)
NEON_URL = os.getenv("NEON_POSTGRES_URL")
# Local Target (Connect via localhost when running on Host machine)
LOCAL_URL = os.getenv("POSTGRES_URL", "").replace("alzai-db", "localhost")

if not NEON_URL or not LOCAL_URL:
    print("❌ ERROR: Missing NEON_POSTGRES_URL or POSTGRES_URL in .env")
    sys.exit(1)

def migrate():
    source_conn = None
    target_conn = None
    
    try:
        print("🔗 Connecting to Source (Neon)...")
        source_conn = psycopg2.connect(NEON_URL)
        source_cur = source_conn.cursor()
        
        print("🏠 Connecting to Target (Local)...")
        target_conn = psycopg2.connect(LOCAL_URL)
        target_cur = target_conn.cursor()
        
        # 1. Discover tables in public schema
        source_cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
            AND table_name NOT LIKE 'alembic_%';
        """)
        tables = [row[0] for row in source_cur.fetchall()]
        
        print(f"📊 Found {len(tables)} tables to migrate: {', '.join(tables)}")
        
        # 2. Disable Foreign Key checks for clean mirror
        target_cur.execute("SET session_replication_role = 'replica';")
        
        summary = []
        
        for table in tables:
            print(f"--- 🔄 Migrating table: {table} ---")
            
            # Get source count
            source_cur.execute(f"SELECT count(*) FROM {table}")
            source_count = source_cur.fetchone()[0]
            
            # Truncate target
            target_cur.execute(f"TRUNCATE TABLE {table} CASCADE;")
            
            # Fetch all data from source
            source_cur.execute(f"SELECT * FROM {table}")
            rows = source_cur.fetchall()
            
            if rows:
                # Prepare insert query
                col_names = [desc[0] for desc in source_cur.description]
                placeholders = ", ".join(["%s"] * len(col_names))
                insert_query = f"INSERT INTO {table} ({', '.join(col_names)}) VALUES ({placeholders})"
                
                # Batch insert
                extras.execute_batch(target_cur, insert_query, rows)
            
            # Validate target count
            target_cur.execute(f"SELECT count(*) FROM {table}")
            target_count = target_cur.fetchone()[0]
            
            print(f"✅ {table}: {target_count}/{source_count} rows copied.")
            summary.append((table, source_count, target_count))
            
        # Re-enable Foreign Key checks
        target_cur.execute("SET session_replication_role = 'origin';")
        target_conn.commit()
        
        print("\n🚀 --- MIGRATION SUMMARY ---")
        for table, s, t in summary:
            status = "MATCH" if s == t else "MISMATCH ⚠️"
            print(f"{table.ljust(20)} | Source: {str(s).ljust(5)} | Target: {str(t).ljust(5)} | {status}")
            
    except Exception as e:
        if target_conn:
            target_conn.rollback()
        print(f"❌ MIGRATION FAILED: {e}")
    finally:
        if source_conn: source_conn.close()
        if target_conn: target_conn.close()

if __name__ == "__main__":
    migrate()
