import os
import cv2
from deepface import DeepFace
from azure.storage.blob import BlobServiceClient

# From your Upload.py
connection_string = os.environ.get("AZURE_STORAGE_CONNECTION_STRING", "")
container_name = "images"

dataset_path = r"D:\DYP HACKATHON\dataset"
group_image_path = r"D:\DYP HACKATHON\group_photo.jpeg"  # your input group image

blob_service_client = BlobServiceClient.from_connection_string(connection_string)

def list_blobs_for_person(person_name):
    container_client = blob_service_client.get_container_client(container_name)
    return list(container_client.list_blobs(name_starts_with=f"{person_name}/"))

def upload_face(local_path, person_name):
    count = len(list_blobs_for_person(person_name)) + 1
    blob_path = f"{person_name}/{person_name}_{count}.jpg"
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_path)
    with open(local_path, "rb") as data:
        blob_client.upload_blob(data, overwrite=True)
    print(f"Uploaded: {blob_path}")

def process_group_image():
    img = cv2.imread(group_image_path)

    face_objs = DeepFace.extract_faces(
        img_path=group_image_path,
        detector_backend="opencv",
        enforce_detection=False
    )

    print(f"Faces detected: {len(face_objs)}")

    for i, face_obj in enumerate(face_objs):
        area = face_obj["facial_area"]
        x, y, w, h = area["x"], area["y"], area["w"], area["h"]
        cropped = img[y:y+h, x:x+w]

        temp_path = f"temp_face_{i}.jpg"
        cv2.imwrite(temp_path, cropped)

        try:
            result = DeepFace.find(
                img_path=temp_path,
                db_path=dataset_path,
                model_name="VGG-Face",
                detector_backend="opencv",
                enforce_detection=False,
                silent=True
            )

            if len(result) > 0 and len(result[0]) > 0:
                match_path = result[0].iloc[0]["identity"]
                person_name = match_path.split(os.sep)[-2]
                print(f"Face {i} -> {person_name}")
                upload_face(temp_path, person_name)
            else:
                print(f"Face {i} -> Unknown, skipping")

        except Exception as e:
            print(f"Face {i} -> Error: {e}")

        if os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == "__main__":
    process_group_image()