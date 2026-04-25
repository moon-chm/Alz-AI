from deepface import DeepFace
import os

DATASET_PATH = r"d:\Alz-AI\azurefaceservice\dataset\dataset"

def test_find():
    # Just list directories to be sure
    dirs = [d for d in os.listdir(DATASET_PATH) if os.path.isdir(os.path.join(DATASET_PATH, d))]
    print(f"Found {len(dirs)} people in dataset: {dirs}")
    
    # Try finding with a dummy image or just verify path
    if os.path.exists(DATASET_PATH):
        print("Path exists. DeepFace ready.")
    else:
        print("Path NOT found!")

if __name__ == "__main__":
    test_find()
