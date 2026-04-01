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
import json
from groq import AsyncGroq
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
            
            print(f"🔎 [Scheduler] Quét giờ: {current_time_str} ({today_str}) - Tìm thấy {len(schedules)} lịch trình cần chạy.")
            
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
                print(f"✅ Đã broadcast kết quả Lịch trình cho Front-end: {device_id} = {action}")
                
                if len(sch.get("repeated_days", [])) == 0:
                    await collection.update_one({"_id": sch["_id"]}, {"$set": {"is_active": False}})
        except Exception as e:
            print(f"❌ Lỗi khi chạy scheduler: {e}")
            
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


# Device IDs thực sự có code phần cứng trên ESP32
FIRMWARE_DEVICE_IDS = ["led_1", "led_2", "fan_1"]

@app.get("/devices")
async def get_all_devices():
    collection = db.db["devices"]
    devices = await collection.find({}, {"_id": 0}).to_list(100)
    # Thêm thông tin has_firmware cho mỗi thiết bị
    for d in devices:
        d["has_firmware"] = d["device_id"] in FIRMWARE_DEVICE_IDS
    return devices


@app.post("/devices")
async def create_device(data: dict = Body(...)):
    """Tạo thiết bị mới từ App (Dynamic Device Registry)"""
    device_id = data.get("device_id")
    if not device_id:
        raise HTTPException(status_code=400, detail="Thiếu device_id")
    
    collection = db.db["devices"]
    existing = await collection.find_one({"device_id": device_id})
    if existing:
        raise HTTPException(status_code=409, detail=f"Thiết bị '{device_id}' đã tồn tại")
    
    now = datetime.utcnow()
    new_device = {
        "device_id": device_id,
        "name": data.get("name", f"Device {device_id}"),
        "type": data.get("type", "unknown"),
        "room": data.get("room", ""),
        "icon": data.get("icon", "devices"),
        "status": False,
        "value": 0.0,
        "created_at": now,
        "updated_at": now,
    }
    
    # Thêm info has_firmware
    new_device["has_firmware"] = device_id in FIRMWARE_DEVICE_IDS
    
    await collection.insert_one(new_device.copy())
    new_device.pop("_id", None)
    
    # Broadcast cho tất cả Flutter clients biết có thiết bị mới
    await ws_manager.broadcast({
        **new_device,
        "type": "device_added", # Đặt sau cùng để không bị **new_device clobber
        "created_at": str(now),
        "updated_at": str(now),
    })
    
    return {"message": f"Đã thêm thiết bị '{new_device['name']}'", "data": new_device}


@app.put("/devices/{device_id}")
async def update_device_info(device_id: str, data: dict = Body(...)):
    """Sửa thông tin thiết bị (tên, phòng, loại, icon)"""
    collection = db.db["devices"]
    update_fields = {}
    for field in ["name", "room", "type", "icon"]:
        if field in data:
            update_fields[field] = data[field]
    
    if not update_fields:
        raise HTTPException(status_code=400, detail="Không có trường nào để cập nhật")
    
    update_fields["updated_at"] = datetime.utcnow()
    result = await collection.update_one({"device_id": device_id}, {"$set": update_fields})
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy thiết bị")
    
    updated = await collection.find_one({"device_id": device_id}, {"_id": 0})
    
    await ws_manager.broadcast({
        **update_fields,
        "type": "device_updated", # Đặt sau cùng
        "device_id": device_id,
        "updated_at": str(update_fields["updated_at"]),
    })
    
    return {"message": "Đã cập nhật thiết bị", "data": updated}


@app.delete("/devices/{device_id}")
async def delete_device(device_id: str):
    """Xóa thiết bị + cascade xóa lịch trình liên quan"""
    collection = db.db["devices"]
    result = await collection.delete_one({"device_id": device_id})
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy thiết bị")
    
    # Cascade: Xóa lịch trình liên quan
    await db.db["schedules"].delete_many({"device_id": device_id})
    # Cascade: Xóa logs liên quan
    await db.db["device_logs"].delete_many({"device_id": device_id})
    
    await ws_manager.broadcast({
        "type": "device_deleted",
        "device_id": device_id,
    })
    
    return {"message": f"Đã xóa thiết bị '{device_id}' và dữ liệu liên quan"}


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

# --- TRỢ LÝ AI (GROQ TỐC ĐỘ BÀN THỜ) ---
@app.post("/ai/chat")
async def ai_chat(req: ChatRequest):
    """Trợ lý ảo xử lý ra lệnh bằng giọng nói (Text) dùng CÔNG NGHỆ LPU SIÊU NHANH CỦA GROQ."""
    if not hasattr(settings, 'GROQ_API_KEY') or not settings.GROQ_API_KEY:
         return {"reply": "Chưa cài đặt biến môi trường GROQ_API_KEY. Bạn lên console.groq.com tạo API Key lấy 1 giây nhé!", "device_id": "none", "action": False}
    
    # Khởi tạo client Groq
    groq_client = AsyncGroq(api_key=settings.GROQ_API_KEY)
    
    # 🔥 DYNAMIC: Query danh sách thiết bị từ MongoDB (không hardcode nữa!)
    all_devices = await db.db["devices"].find({}, {"_id": 0, "device_id": 1, "name": 1, "room": 1, "type": 1}).to_list(100)
    
    # Gắn has_firmware cho AI biết
    device_list = []
    for d in all_devices:
        has_fw = d["device_id"] in FIRMWARE_DEVICE_IDS
        fw_status = "ĐÃ CÓ PHẦN CỨNG" if has_fw else "CHƯA CÓ PHẦN CỨNG (Cần nạp FW)"
        device_list.append(f'- "{d["device_id"]}": {d.get("name", d["device_id"])} (phòng: {d.get("room", "N/A")}, loại: {d.get("type", "unknown")}) -> TRẠNG THÁI: {fw_status}')
    
    device_list_str = "\n".join(device_list) if device_list else '- Chưa có thiết bị nào được đăng ký.'
    
    valid_ids = [d["device_id"] for d in all_devices]
    valid_ids_str = " hoặc ".join([f'"{vid}"' for vid in valid_ids]) + ' hoặc "all" hoặc "none"' if valid_ids else '"none"'
    
    prompt = f"""Bạn tên là "Nhà" — trợ lý ảo của hệ thống nhà thông minh AIoT SmartHome.
Tính cách: Bạn nói chuyện như một người bạn thân, vui vẻ, tự nhiên, hài hước nhẹ nhàng, KHÔNG cứng nhắc hay lễ phép quá mức. Dùng ngôn ngữ đời thường, gần gũi kiểu gen Z Việt Nam. Có thể dùng emoji khi phù hợp.

Người dùng vừa nói: "{req.message}"

DANH SÁCH THIẾT BỊ HỆ THỐNG:
{device_list_str}

QUY TẮC QUAN TRỌNG:
1. Nếu muốn BẬT/TẮT thiết bị → trả JSON với device_id tương ứng, action = true (bật) hoặc false (tắt).
2. "bật/tắt hết", "tắt tất cả" → chọn thiết bị phù hợp nhất hoặc device_id="all".
3. Nếu người dùng muốn điều khiển thiết bị có trạng thái "CHƯA CÓ PHẦN CỨNG", hãy vẫn trả về JSON đúng device_id nhưng trong "reply" hãy nhắc khéo họ là "Thiết bị này mới thêm trên app thôi chứ chưa nạp code firmware vào ESP32 đâu, nhớ nạp nhé bạn hiền!".
4. Nếu người dùng chỉ nói chuyện bình thường, hỏi thăm, tâm sự → trả lời vui vẻ, device_id="none", action=false.
5. Yêu cầu thời tiết, nhiệt độ → bảo họ xem dashboard, device_id="none".
6. Câu trả lời cực ngắn gọn, tự nhiên và trẻ trung.

Trả về ĐÚNG 1 chuỗi JSON, KHÔNG markdown, KHÔNG text thừa:
{{
  "device_id": {valid_ids_str},
  "action": true hoặc false,
  "reply": "câu trả lời tự nhiên kiểu bạn bè"
}}
"""
    try:
        response = await groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )
        
        text = response.choices[0].message.content.replace("```json", "").replace("```", "").strip()
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
        return {"reply": f"Dạ, em bị lỗi não bộ: {str(e)}", "device_id": "none", "action": False}