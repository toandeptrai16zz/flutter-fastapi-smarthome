from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List
from datetime import datetime
import sys
import asyncio
from bson import ObjectId
from app.models.schedule import ScheduleCreate

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from app.core.database import connect_to_mongo, close_mongo_connection, db
from app.services.mqtt_service import mqtt


async def run_scheduler_loop():
    while db.db is None:
        await asyncio.sleep(1)
        
    print("🕒 Bắt đầu tiến trình kiểm tra lịch trình (Scheduler)...")
    while True:
        now = datetime.now() # Lấy giờ Local
        current_time_str = now.strftime("%H:%M")
        weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        today_str = weekdays[now.weekday()]
        
        try:
            collection = db.db["schedules"]
            query = {
                "is_active": True,
                "time": current_time_str,
                "$or": [
                    {"repeated_days": {"$size": 0}},
                    {"repeated_days": today_str}
                ]
            }
            schedules = await collection.find(query).to_list(100)
            for sch in schedules:
                device_id = sch["device_id"]
                action = sch["action"]
                payload = "ON" if action else "OFF"
                print(f"⏰ Kích hoạt lịch trình: {device_id} -> {payload}")
                
                await mqtt.publish(f"smarthome/devices/{device_id}/control", payload)
                await db.db["devices"].update_one(
                    {"device_id": device_id},
                    {"$set": {"status": action, "updated_at": datetime.utcnow()}}
                )
                
                if len(sch.get("repeated_days", [])) == 0:
                    await collection.update_one({"_id": sch["_id"]}, {"$set": {"is_active": False}})
        except Exception as e:
            print(f"Lỗi khi chạy scheduler: {e}")
            
        seconds_to_next_minute = 60 - datetime.now().second
        await asyncio.sleep(seconds_to_next_minute)


scheduler_task = None

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


@app.get("/sensors/latest")
async def get_latest_sensors():
    """Lấy dữ liệu cảm biến (Nhiệt độ, Độ ẩm) mới nhất từ tất cả cảm biến"""
    # Lấy 1 bản ghi mới nhất (theo timestamp) từ bảng sensors
    latest_sensor = await db.db["sensors"].find_one(
        {}, 
        {"_id": 0},
        sort=[("timestamp", -1)]
    )
    if latest_sensor:
        return latest_sensor
    return {
        "device_id": "none",
        "temperature": 0.0,
        "humidity": 0.0,
        "timestamp": datetime.utcnow()
    }

# --- QUẢN LÝ LỊCH TRÌNH (SCHEDULES) ---

@app.get("/schedules")
async def get_schedules():
    """Lấy danh sách tất cả lịch trình"""
    collection = db.db["schedules"]
    schedules = await collection.find({}).to_list(100)
    for sch in schedules:
        sch["id"] = str(sch.pop("_id"))
    return schedules

@app.post("/schedules")
async def create_schedule(schedule: ScheduleCreate):
    """Tạo mới một lịch trình"""
    collection = db.db["schedules"]
    now = datetime.utcnow()
    doc = schedule.model_dump()
    doc["created_at"] = now
    result = await collection.insert_one(doc)
    
    # Loại bỏ ObjectId trước khi trả về để tránh lỗi serialize của FastAPI
    doc.pop("_id", None)
    doc["id"] = str(result.inserted_id)
    return doc

@app.delete("/schedules/{schedule_id}")
async def delete_schedule(schedule_id: str):
    """Xóa một lịch trình bằng ID"""
    collection = db.db["schedules"]
    await collection.delete_one({"_id": ObjectId(schedule_id)})
    return {"message": "Đã xóa lịch trình"}

@app.put("/schedules/{schedule_id}/toggle")
async def toggle_schedule(schedule_id: str):
    """Bật/tắt trạng thái is_active của lịch trình"""
    collection = db.db["schedules"]
    item = await collection.find_one({"_id": ObjectId(schedule_id)})
    if not item:
        raise HTTPException(status_code=404, detail="Không tìm thấy lịch trình")
    new_status = not item.get("is_active", True)
    await collection.update_one({"_id": ObjectId(schedule_id)}, {"$set": {"is_active": new_status}})
    return {"message": "Đã đổi trạng thái", "is_active": new_status}