from deepface import DeepFace
import json
import os
import uuid
from scipy.spatial.distance import cosine
import requests
from app.services.cloudinary_service import upload_file
from app.services.memory_service import register_face_to_family_member, get_family

def register_face(image_path: str, patient_id: str, family_member_id: str, family_member_name: str) -> dict:
    try:
        # 1) Extract embedding
        embedding_obj = DeepFace.represent(img_path=image_path, model_name='VGG-Face', enforce_detection=False)
        embedding = embedding_obj[0]["embedding"]
        
        # 2) Save to temp
        temp_json = f"/tmp/enc_{uuid.uuid4()}.json"
        with open(temp_json, "w") as f:
            json.dump(embedding, f)
            
        # 3) Upload JSON to Cloudinary
        folder = f"face-encodings/{patient_id}"
        url = upload_file(temp_json, folder, resource_type='raw')
        
        # 4) Update Neo4j
        register_face_to_family_member(family_member_id, url)
        
        # 5) Delete temp
        if os.path.exists(temp_json):
            os.remove(temp_json)
            
        return {"success": True, "encoding_url": url}
    except Exception as e:
        return {"success": False, "error": str(e)}

def recognize_face(image_path: str, patient_id: str) -> dict:
    # 1) Fetch all family nodes
    family_nodes = get_family(patient_id)
    best_match = None
    min_dist = float('inf')
    
    try:
        # Extract input embedding
        input_emb = DeepFace.represent(img_path=image_path, model_name='VGG-Face', enforce_detection=False)[0]["embedding"]
        
        # 2) For each member
        for node in family_nodes:
            f = node.get("f", {})
            url = f.get("face_encoding_path")
            if not url:
                continue
                
            # Download encoding
            res = requests.get(url)
            if res.status_code == 200:
                saved_emb = res.json()
                dist = cosine(input_emb, saved_emb)
                if dist < min_dist:
                    min_dist = dist
                    best_match = f
                    
        # 3) Threshold check
        if min_dist < 0.4 and best_match:
            return {"matched": True, "family_member": best_match, "confidence": 1.0 - min_dist}
        else:
            return {"matched": False, "family_member": None, "confidence": 0}
            
    except Exception as e:
        return {"matched": False, "error": str(e)}
