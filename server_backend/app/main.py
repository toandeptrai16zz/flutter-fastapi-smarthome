from fastapi import FastAPI, HTTPException, Body, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List
from datetime import datetime
import sys
import asyncio
from bson import ObjectId
from pydantic import BaseModel
from app.models.schedule import ScheduleCreate
from app.core.config import settings
import json
from groq import AsyncGroq
from app.services.websocket_manager import ws_manager
from app.api import auth

class ChatRequest(BaseModel):
    message: str


from app.core.database import connect_to_mongo, close_mongo_connection, db
from app.services.mqtt_service import mqtt


from app.services.scheduler_service import run_scheduler_loop

scheduler_task = None
FIRMWARE_DEVICE_IDS = ["led_1", "fan_1", "ac_1", "led_2", "led_3", "led_4"] # Danh sách các ID thiết bị có firmware thực tế

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    await mqtt.start()
    global scheduler_task
    scheduler_task = asyncio.create_task(run_scheduler_loop())
    yield
    if scheduler_task:
        scheduler_task.cancel()
    if mqtt.task:
        mqtt.task.cancel()
    await close_mongo_connection()


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.routers import devices, schedules, ai_chat

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(devices.router, tags=["devices"])
app.include_router(schedules.router, tags=["schedules"])
app.include_router(ai_chat.router, tags=["ai"])



@app.get("/")
def read_root():
    return {"message": "IoT SmartHome Server - MongoDB + MQTT!"}


# ═════════════════════════════════
# WEBSOCKET ENDPOINT
# ═════════════════════════════════
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    print(f"📡 New WS connection request from {websocket.client}")
    await ws_manager.connect(websocket)
    try:
        if db.db is not None:
            devices = await db.db["devices"].find({}, {"_id": 0}).to_list(100)
            for d in devices:
                d["has_firmware"] = d["device_id"] in FIRMWARE_DEVICE_IDS or d.get("gpio_pin") is not None
                if d.get("gpio_pin"):
                    for label, pin in settings.ESP32_PIN_MAP.items():
                        if pin == d["gpio_pin"]:
                            d["pin_label"] = label
                            break
            
            sensor = await db.db["sensors"].find_one({}, {"_id": 0}, sort=[("timestamp", -1)])
            await websocket.send_text(json.dumps({
                "type": "init",
                "devices": devices,
                "sensor": {
                    "temperature": sensor.get("temperature", 0.0) if sensor else 0.0,
                    "humidity": sensor.get("humidity", 0.0) if sensor else 0.0
                }
            }, ensure_ascii=False, default=str))
        
        while True:
            await websocket.receive_text()
            await websocket.send_text(json.dumps({"type": "pong"}))
            
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        ws_manager.disconnect(websocket)

