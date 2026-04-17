import os
from neo4j import GraphDatabase
from dotenv import load_dotenv
import sys

# Load environment variables
load_dotenv()

# Cloud Source (AuraDB)
AURA_URI = os.getenv("AURA_NEO4J_URI")
AURA_USER = os.getenv("AURA_NEO4J_USER", "neo4j")
AURA_PWD = os.getenv("AURA_NEO4J_PASSWORD")
AURA_DB = os.getenv("AURA_NEO4J_DATABASE", "neo4j")

# Local Target
LOCAL_URI = os.getenv("NEO4J_URI", "").replace("neo4j", "localhost")
LOCAL_USER = os.getenv("NEO4J_USERNAME", "neo4j")
LOCAL_PWD = os.getenv("NEO4J_PASSWORD")

if not AURA_URI or not AURA_PWD or not LOCAL_URI:
    print("❌ ERROR: Missing AURA_NEO4J credentials or LOCAL_NEO4J_URI in .env")
    sys.exit(1)

def migrate():
    aura_driver = None
    local_driver = None
    
    # Try +ssc protocols which tell the driver to skip SSL verification (Self-Signed Certificate mode)
    protocols_to_try = []
    if AURA_URI:
        base_uri = AURA_URI.split("://")[-1]
        protocols_to_try.append(f"neo4j+ssc://{base_uri}")
        protocols_to_try.append(f"bolt+ssc://{base_uri}")

    for uri in protocols_to_try:
        try:
            print(f"🔗 Attempting connection to Source: {uri} (Database: {AURA_DB})...")
            aura_driver = GraphDatabase.driver(
                uri, 
                auth=(AURA_USER, AURA_PWD),
                max_connection_lifetime=30,
                keep_alive=True
            )
            aura_driver.verify_connectivity()
            print(f"✅ Successfully connected to Source via {uri.split('://')[0]}")
            break
        except Exception as e:
            print(f"⚠️ Connection failed via {uri.split('://')[0]}: {e}")
            if aura_driver: aura_driver.close()
            aura_driver = None

    if not aura_driver:
        print("❌ CRITICAL: All connection protocols failed for AuraDB.")
        return

    try:
        print(f"🏠 Connecting to Target (Local): {LOCAL_URI}...")
        local_driver = GraphDatabase.driver(LOCAL_URI, auth=(LOCAL_USER, LOCAL_PWD))
        local_driver.verify_connectivity()
        
        # 1. Fetch all Nodes
        print(f"🔍 Fetching all nodes from Source ({AURA_DB})...")
        nodes = []
        with aura_driver.session(database=AURA_DB) as session:
            result = session.run("MATCH (n) RETURN n, labels(n) as labels")
            for record in result:
                node = record["n"]
                nodes.append({
                    "labels": record["labels"],
                    "properties": dict(node)
                })
        
        print(f"📦 Found {len(nodes)} nodes.")
        
        if len(nodes) > 0:
            # 2. Recreate Nodes locally using MERGE
            print("🚢 Migrating nodes to Local...")
            with local_driver.session() as session:
                for node in nodes:
                    labels = ":".join(node["labels"])
                    # Use 'id' or other unique property
                    unique_key = "id" if "id" in node["properties"] else list(node["properties"].keys())[0]
                    query = f"MERGE (n:{labels} {{{unique_key}: $props.{unique_key}}}) SET n = $props"
                    session.run(query, props=node["properties"])
        
            # 3. Fetch all Relationships
            print(f"🔍 Fetching all relationships from Source ({AURA_DB})...")
            rels = []
            with aura_driver.session(database=AURA_DB) as session:
                result = session.run("""
                    MATCH (a)-[r]->(b) 
                    RETURN labels(a) as a_labels, 
                           a.id as a_id, a.full_name as a_name, a.name as a_short_name,
                           type(r) as r_type, properties(r) as r_props,
                           labels(b) as b_labels, 
                           b.id as b_id, b.full_name as b_name, b.name as b_short_name
                """)
                for record in result:
                    rels.append(record)
            
            print(f"🔗 Found {len(rels)} relationships.")
            
            # 4. Recreate Relationships locally
            print("🚢 Migrating relationships to Local...")
            with local_driver.session() as session:
                for r in rels:
                    # Determine identifiers dynamically
                    a_val = r["a_id"] or r["a_name"] or r["a_short_name"]
                    a_key = "id" if r["a_id"] else ("full_name" if r["a_name"] else "name")
                    
                    b_val = r["b_id"] or r["b_name"] or r["b_short_name"]
                    b_key = "id" if r["b_id"] else ("full_name" if r["b_name"] else "name")
                    
                    a_labels = ":".join(r["a_labels"])
                    b_labels = ":".join(r["b_labels"])
                    
                    query = f"""
                        MATCH (a:{a_labels} {{{a_key}: $a_val}})
                        MATCH (b:{b_labels} {{{b_key}: $b_val}})
                        MERGE (a)-[r:{r["r_type"]}]->(b)
                        SET r = $r_props
                    """
                    session.run(query, a_val=a_val, b_val=b_val, r_props=r["r_props"])
        
        # 5. Validation
        print("\n🚀 --- MIGRATION SUMMARY ---")
        with local_driver.session() as session:
            node_count = session.run("MATCH (n) RETURN count(n)").single()[0]
            rel_count = session.run("MATCH ()-[r]->() RETURN count(r)").single()[0]
            print(f"Nodes Migrated: {node_count}")
            print(f"Relationships Migrated: {rel_count}")
            if node_count == 0 and len(nodes) > 0:
                print("⚠️ WARNING: Source nodes found but local insertion failed.")
            elif node_count == 0:
                 print("⚠️ WARNING: Source database appears empty.")
            else:
                print("Status: SUCCESS ✅")

    except Exception as e:
        print(f"❌ MIGRATION FAILED: {e}")
    finally:
        if aura_driver: aura_driver.close()
        if local_driver: local_driver.close()

if __name__ == "__main__":
    migrate()
