import asyncio
import json
import redis.asyncio as aioredis
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.config import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(tags=["websocket"])

class WebSocketManager:
    def __init__(self):
        self.connections: dict[str, list[WebSocket]] = {}
    
    async def connect(self, patient_id: str, ws: WebSocket):
        await ws.accept()
        if patient_id not in self.connections:
            self.connections[patient_id] = []
        self.connections[patient_id].append(ws)
        logger.info(f"WebSocket connected: {patient_id}, total: {len(self.connections[patient_id])}")
    
    def disconnect(self, patient_id: str, ws: WebSocket):
        if patient_id in self.connections:
            try:
                self.connections[patient_id].remove(ws)
            except ValueError:
                pass
            if not self.connections[patient_id]:
                del self.connections[patient_id]
        logger.info(f"WebSocket disconnected: {patient_id}")
    
    async def broadcast(self, patient_id: str, message: str):
        if patient_id not in self.connections:
            return
        dead_sockets = []
        for ws in self.connections[patient_id]:
            try:
                await ws.send_text(message)
            except Exception:
                dead_sockets.append(ws)
        # Prune dead sockets
        for ws in dead_sockets:
            try:
                self.connections[patient_id].remove(ws)
            except ValueError:
                pass

manager = WebSocketManager()

async def redis_listener(patient_id: str):
    """Listen to Redis pub/sub channel and broadcast to WebSocket clients."""
    try:
        r = aioredis.from_url(settings.redis_url)
        pubsub = r.pubsub()
        channel = f"patient:{patient_id}:events"
        await pubsub.subscribe(channel)
        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    data = message["data"]
                    if isinstance(data, bytes):
                        data = data.decode('utf-8')
                    await manager.broadcast(patient_id, data)
        except asyncio.CancelledError:
            pass
        finally:
            await pubsub.unsubscribe(channel)
            await r.aclose()
    except Exception as e:
        logger.error(f"Redis WS listener error for {patient_id}: {e}")

@router.websocket("/ws/{patient_id}")
async def websocket_endpoint(websocket: WebSocket, patient_id: str):
    await manager.connect(patient_id, websocket)
    listener_task = asyncio.create_task(redis_listener(patient_id))
    try:
        while True:
            # Keep connection alive, receive any client messages
            data = await websocket.receive_text()
            # Echo back or handle ping/pong
    except WebSocketDisconnect:
        pass
    finally:
        listener_task.cancel()
        manager.disconnect(patient_id, websocket)
