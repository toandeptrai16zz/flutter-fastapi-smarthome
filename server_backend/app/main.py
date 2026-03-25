from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List
from datetime import datetime
import sys
import asyncio

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from app.core.database import connect_to_mongo, close_mongo_connection, db
from app.services.mqtt_service import mqtt


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    await mqtt.start()
    yield
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


@app.get("/")
def read_root():
    return {"message": "IoT SmartHome Server - MongoDB + MQTT!"}


@app.get("/devices")
async def get_all_devices():
    collection = db.db["devices"]
    devices = await collection.find({}, {"_id": 0}).to_list(100)
    return devices


@app.get("/device/{device_id}")
async def get_device_status(device_id: str):
    collection = db.db["devices"]
    device = await collection.find_one({"device_id": device_id}, {"_id": 0})
    if device:
        return device

    # Tự tạo nếu chưa có
    new_device = {
        "device_id": device_id,
        "name": f"Device {device_id}",
        "type": "unknown",
        "room": "",
        "status": False,
        "value": 0.0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    }
    await collection.insert_one(new_device.copy())
    new_device.pop("_id", None)
    return new_device


@app.post("/device/update")
async def update_device_status(data: dict = Body(...)):
    device_id = data.get("device_id")
    status = data.get("status")

    if device_id is None or status is None:
        raise HTTPException(status_code=400, detail="Thiếu device_id hoặc status")

    now = datetime.utcnow()
    collection = db.db["devices"]

    result = await collection.update_one(
        {"device_id": device_id},
        {"$set": {"status": bool(status), "updated_at": now}}
    )

    if result.matched_count == 0:
        await collection.insert_one({
            "device_id": device_id,
            "name": f"Device {device_id}",
            "type": "unknown",
            "room": "",
            "status": bool(status),
            "value": 0.0,
            "created_at": now,
            "updated_at": now,
        })

    # Ghi vào device_logs
    await db.db["device_logs"].insert_one({
        "device_id": device_id,
        "status": bool(status),
        "timestamp": now,
    })

    # Bắn MQTT xuống ESP
    payload = "ON" if status else "OFF"
    success = await mqtt.publish(f"smarthome/devices/{device_id}/control", payload)

    updated = await collection.find_one({"device_id": device_id}, {"_id": 0})
    if not success:
        return {"message": "Cập nhật DB OK nhưng lỗi gửi lệnh tới thiết bị!", "data": updated}

    return {"message": "Cập nhật thành công!", "data": updated}


@app.get("/device/{device_id}/logs")
async def get_device_logs(device_id: str, limit: int = 20):
    """Lấy lịch sử bật/tắt của 1 thiết bị"""
    logs = await db.db["device_logs"].find(
        {"device_id": device_id},
        {"_id": 0}
    ).sort("timestamp", -1).limit(limit).to_list(limit)
    return logs