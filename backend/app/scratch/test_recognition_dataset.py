import os
import sys

# Add backend to path
sys.path.append(r"d:\Alz-AI\backend")

# Mock settings/env if needed
os.environ["SYSTEM_MODE"] = "DEMO"

from app.services.deepface_service import recognize_face

TEST_IMAGE = r"d:\Alz-AI\azurefaceservice\dataset\dataset\Rohit\Rohit_1.jpeg"
# We need a dummy patient_id for relationship lookup
PATIENT_ID = "9d2e0181-ad62-47a2-b6f1-c64d3d228179" 

def test_recognition():
    print(f"Testing recognition with: {TEST_IMAGE.encode('ascii', 'ignore').decode('ascii')}")
    try:
        result = recognize_face(TEST_IMAGE, PATIENT_ID)
        # Convert result to string and filter non-ascii for console safety
        res_str = str(result)
        print("Result:", res_str.encode('ascii', 'ignore').decode('ascii'))
    except Exception as e:
        print(f"Error in test: {e}")

if __name__ == "__main__":
    test_recognition()
