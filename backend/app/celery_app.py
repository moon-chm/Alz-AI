from celery import Celery
from app.config import settings
import os

# Initialize Celery
# The broker and backend URLs are taken from the settings
celery_app = Celery(
    "alzai",
    broker=settings.redis_url,
    backend=settings.redis_url
)

# Celery Configuration (Mandatory per requirements)
celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",  # Ensure consistency with backend
    enable_utc=True,
    task_track_started=True,
    task_ignore_result=False,
    broker_connection_retry_on_startup=True,
    # Discover tasks in app.services and app.tasks
    include=["app.tasks.mri_tasks"]
)

if __name__ == "__main__":
    celery_app.start()
