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
import google.generativeai as genai

# Import WebSocket Manager từ file riêng (tránh circular import)
from app.services.websocket_manager import ws_manager
from app.api import auth

class ChatRequest(BaseModel):
    message: str


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
                await db.db["device_logs"].insert_one({
                    "device_id": device_id,
                    "status": action,
                    "timestamp": datetime.utcnow()
                })
                # Báo cho Flutter app để cập nhật UI ngay lập tức
                await ws_manager.broadcast({
                    "type": "device_update",
                    "device_id": device_id,
                    "status": action
                })
                
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

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])



@app.get("/")
def read_root():
    return {"message": "IoT SmartHome Server - MongoDB + MQTT!"}


# ═══════════════════════════════════════════════════════════
# WEBSOCKET ENDPOINT - Cho phép Flutter kết nối Realtime
# ═══════════════════════════════════════════════════════════
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    print(f"📡 New WS connection request from {websocket.client}")
    await ws_manager.connect(websocket)
    try:
        # Gửi snapshot trạng thái hiện tại ngay khi kết nối
        if db.db is not None:
            devices = await db.db["devices"].find({}, {"_id": 0}).to_list(100)
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
            # Nhận message từ client (nếu có)
            data = await websocket.receive_text()
            # Trả lời pong để giữ connection
            await websocket.send_text(json.dumps({"type": "pong"}))
            
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        print(f"❌ WS Error: {e}")
        ws_manager.disconnect(websocket)


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
    
    # 🔴 Broadcast realtime tới tất cả Flutter clients qua WebSocket
    await ws_manager.broadcast({
        "type": "device_update",
        "device_id": device_id,
        "status": bool(status)
    })

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

# --- TRỢ LÝ AI (GEMINI) ---
@app.post("/ai/chat")
async def ai_chat(req: ChatRequest):
    """Trợ lý ảo xử lý ra lệnh bằng giọng nói (Text)"""
    if not settings.GEMINI_API_KEY:
        return {"reply": "Chưa cài đặt API Key cho AI.", "device_id": "none", "action": False}
    
    genai.configure(api_key=settings.GEMINI_API_KEY)
    # Dùng gemini-2.5-flash cho tốc độ phản hồi cực nhanh -> tối ưu trải nghiệm Assistant
    model = genai.GenerativeModel('gemini-2.5-flash')
    
    prompt = f"""Bạn là một trợ lý ảo quản lý nhà thông minh tên là "Nhà".
Người dùng vừa ra lệnh: "{req.message}"

Dưới đây là danh sách thiết bị bạn có thể điều khiển:
- "led_1": Đèn Phòng Khách
- "led_2": Đèn Phòng Ngủ
Bạn phải chọn hành động là `true` (BẬT) hoặc `false` (TẮT).

Hãy trả về chuỗi JSON CHUẨN như sau, KHÔNG có markdown, KHÔNG có text thừa:
{{
  "device_id": "led_1/led_2/none",
  "action": true/false,
  "reply": "Dạ em đã bật đèn phòng khách rồi ạ" (câu trả lời bằng tiếng Việt mềm mỏng đáng yêu để đọc ra loa)
}}
Nếu không hiểu hoặc không nói về thiết bị hiện có, trả về device_id="none", action=false và reply="Dạ em chưa hiểu ý anh ạ."
"""
    try:
        response = model.generate_content(prompt)
        text = response.text.replace("```json", "").replace("```", "").strip()
        data = json.loads(text)
        
        device_id = data.get("device_id")
        action = data.get("action")
        reply = data.get("reply", "Dạ em đã xử lý xong.")
        
        if device_id and device_id != "none":
            # Gửi lệnh MQTT
            topic = f"smarthome/devices/{device_id}/control"
            payload = "ON" if action else "OFF"
            if mqtt.client:
                mqtt.client.publish(topic, payload)
            
            # Cập nhật DB
            if db.db is not None:
                collection = db.db["devices"]
                await collection.update_one(
                    {"device_id": device_id},
                    {"$set": {"status": action, "updated_at": datetime.utcnow()}}
                )
            
            # 🔴 Broadcast realtime qua WebSocket
            await ws_manager.broadcast({
                "type": "device_update",
                "device_id": device_id,
                "status": action
            })
            
        return {"reply": reply, "device_id": device_id, "action": action}
    except Exception as e:
        print(f"Lỗi AI: {e}")
        return {"reply": "Dạ, hiện tại em đang bị lỗi kết nối mạng não bộ ạ.", "device_id": "none", "action": False}
        raise HTTPException(status_code=500, detail=str(e))