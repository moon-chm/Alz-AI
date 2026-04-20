import boto3
from botocore.client import Config
from botocore.exceptions import ClientError
from app.config import settings
import logging
import hashlib

logger = logging.getLogger(__name__)

class MinIOService:
    def __init__(self):
        self.endpoint = settings.minio_endpoint.replace("http://", "").replace("https://", "")
        self.access_key = settings.minio_root_user
        self.secret_key = settings.minio_root_password
        self.bucket_name = settings.minio_bucket
        self.use_ssl = "https" in settings.minio_endpoint
        
        self.s3 = boto3.client(
            "s3",
            endpoint_url=settings.minio_endpoint,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            config=Config(signature_version="s3v4"),
            region_name="us-east-1" # MinIO default
        )
        self._ensure_bucket_exists()

    def _ensure_bucket_exists(self):
        """Programmatic bucket creation (Mandatory per requirements)"""
        try:
            self.s3.head_bucket(Bucket=self.bucket_name)
            logger.info(f"✅ MinIO: Bucket '{self.bucket_name}' already exists.")
        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code")
            if error_code == "404":
                try:
                    self.s3.create_bucket(Bucket=self.bucket_name)
                    logger.info(f"🚀 MinIO: Bucket '{self.bucket_name}' created successfully.")
                except Exception as ex:
                    logger.error(f"❌ MinIO: Failed to create bucket: {ex}")
            else:
                logger.error(f"❌ MinIO: Error checking bucket: {e}")

    def upload_file(self, file_content: bytes, object_name: str, content_type: str = "application/octet-stream") -> str:
        """Uploads file with hierarchy and returns MD5 checksum"""
        try:
            # Calculate MD5 checksum
            checksum = hashlib.md5(file_content).hexdigest()
            
            self.s3.put_object(
                Bucket=self.bucket_name,
                Key=object_name,
                Body=file_content,
                ContentType=content_type,
                Metadata={"md5": checksum}
            )
            return checksum
        except Exception as e:
            logger.error(f"❌ MinIO: Upload failed: {e}")
            raise e

    def get_signed_url(self, object_name: str, expires_in_minutes: int = None) -> str:
        """Generates a temporary signed URL (Mandatory per requirements)"""
        if expires_in_minutes is None:
            expires_in_minutes = getattr(settings, "mri_url_expiry_minutes", 60)
            
        try:
            url = self.s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": self.bucket_name, "Key": object_name},
                ExpiresIn=expires_in_minutes * 60
            )
            return url
        except Exception as e:
            logger.error(f"❌ MinIO: Failed to generate signed URL: {e}")
            return None

    def delete_file(self, object_name: str) -> bool:
        try:
            self.s3.delete_object(Bucket=self.bucket_name, Key=object_name)
            return True
        except Exception as e:
            logger.error(f"❌ MinIO: Delete failed: {e}")
            return False

# Singleton instance
storage_service = MinIOService()
