from neo4j import GraphDatabase
from contextlib import contextmanager
from app.config import settings

# Handle host vs container resolution for 'neo4j'
import socket

uri = settings.neo4j_uri
try:
    # Check if 'neo4j' hostname is resolvable (true inside Docker network)
    socket.gethostbyname("neo4j")
except socket.gaierror:
    # Not resolvable, assume we are running on host machine
    if "neo4j:7687" in uri:
        uri = uri.replace("neo4j", "localhost")

driver = GraphDatabase.driver(
    uri,
    auth=(settings.neo4j_username, settings.neo4j_password)
)

def verify_connection():
    try:
        driver.verify_connectivity()
        print("Neo4j Connected successfully!")
    except Exception as e:
        print(f"Neo4j Connection Error: {e}")

verify_connection()

@contextmanager
def get_neo4j_session():
    session = driver.session()
    try:
        yield session
    finally:
        session.close()

def close_driver():
    driver.close()
