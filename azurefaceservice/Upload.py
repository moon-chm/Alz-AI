import os
from azure.storage.blob import BlobServiceClient

connection_string = os.environ.get("AZURE_STORAGE_CONNECTION_STRING", "")
container_name = "images"

blob_service_client = BlobServiceClient.from_connection_string(connection_string)

def upload_image(file_path, person_name, file_name):
    blob_path = f"{person_name}/{file_name}"

    blob_client = blob_service_client.get_blob_client(
        container=container_name,
        blob=blob_path
    )

    with open(file_path, "rb") as data:
        blob_client.upload_blob(data, overwrite=True)

    print(f"Uploaded: {blob_path}")


# 🔥 IMPORTANT: set your dataset path here
dataset_path = r"D:\DYP HACKATHON\dataset"

for person_name in os.listdir(dataset_path):
    person_folder = os.path.join(dataset_path, person_name)

    if not os.path.isdir(person_folder):
        continue

    for file_name in os.listdir(person_folder):
        file_path = os.path.join(person_folder, file_name)

        upload_image(file_path, person_name, file_name)