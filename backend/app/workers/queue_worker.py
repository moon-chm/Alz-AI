import asyncio
import json
import traceback
import redis.asyncio as redis
from app.config import settings
from app.workers.job_definitions import job_definitions_map

redis_client = redis.from_url(settings.redis_url, decode_responses=True)
semaphore = asyncio.Semaphore(10)

async def process_job(queue_name: str, payload_str: str):
    async with semaphore:
        try:
            payload = json.loads(payload_str)
            job_name = payload.get("job_name", "alert_dispatch_job")
            job_func = job_definitions_map.get(job_name)
            if job_func:
                print(f"🚀 EXECUTING JOB: {job_name} on {queue_name}")
                await job_func(payload)
                print(f"✅ JOB COMPLETED: {job_name}")
        except Exception as e:
            print(f"Job failed on {queue_name}: {e}")
            traceback.print_exc()

async def poll_queue(queue_name: str, interval: float):
    while True:
        try:
            job = await redis_client.rpop(queue_name)
            if job:
                asyncio.create_task(process_job(queue_name, job))
            else:
                await asyncio.sleep(interval)
        except Exception as e:
            await asyncio.sleep(1)

async def start_workers():
    await asyncio.gather(
        poll_queue("queue:1:critical", 1.0),
        poll_queue("queue:2:standard", 5.0),
        poll_queue("queue:3:background", 30.0)
    )

if __name__ == "__main__":
    asyncio.run(start_workers())
