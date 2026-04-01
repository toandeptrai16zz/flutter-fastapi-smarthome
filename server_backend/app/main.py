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
                
                # 🔥 Đồng bộ logic với điều khiển tay
                device = await db.db["devices"].find_one({"device_id": device_id})
                if not device: continue
                
                gpio_pin = device.get("gpio_pin")
                is_inverted = device.get("is_inverted", False)
                
                actual_status = action
                if is_inverted: actual_status = not action
                
                if gpio_pin is not None:
                    topic = "smarthome/esp/gpio/control"
                    payload = json.dumps({"pin": gpio_pin, "action": "on" if actual_status else "off"})
                else:
                    topic = f"smarthome/devices/{device_id}/control"
                    payload = "ON" if actual_status else "OFF"
                
                print(f"⏰ Kích hoạt lịch trình: {device_id} (Pin: {gpio_pin}) -> {payload}")
                
                await mqtt.publish(topic, payload)
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
                    "event": "device_update",
                    "data": {
                        "device_id": device_id,
                        "status": action
                    }
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


FIRMWARE_DEVICE_IDS = ["led_1", "led_2", "fan_1", "den_ngu", "den_phong_khach"]

@app.get("/devices")
async def get_all_devices():
    collection = db.db["devices"]
    devices = await collection.find({}, {"_id": 0}).to_list(100)
    for d in devices:
        d["has_firmware"] = d["device_id"] in FIRMWARE_DEVICE_IDS or d.get("gpio_pin") is not None
        if d.get("gpio_pin"):
            for label, pin in settings.ESP32_PIN_MAP.items():
                if pin == d["gpio_pin"]:
                    d["pin_label"] = label
                    break
    return devices


@app.get("/devices/available-pins")
async def get_available_pins():
    collection = db.db["devices"]
    used_pins = await collection.distinct("gpio_pin")
    used_pins = [p for p in used_pins if p is not None]
    
    available = []
    for label, pin in settings.ESP32_PIN_MAP.items():
        available.append({
            "label": label,
            "pin": pin,
            "is_used": pin in used_pins
        })
    return available


@app.post("/devices")
async def create_device(data: dict = Body(...)):
    device_id = data.get("device_id")
    if not device_id: raise HTTPException(status_code=400, detail="Thiếu device_id")
    
    collection = db.db["devices"]
    existing = await collection.find_one({"device_id": device_id})
    if existing: raise HTTPException(status_code=409, detail="Đã tồn tại")
    
    now = datetime.utcnow()
    new_device = {
        "device_id": device_id,
        "name": data.get("name", f"Device {device_id}"),
        "type": data.get("type", "unknown"),
        "room": data.get("room", ""),
        "icon": data.get("icon", "devices"),
        "gpio_pin": data.get("gpio_pin"),
        "is_inverted": data.get("is_inverted", False),
        "status": False,
        "value": 0.0,
        "created_at": now,
        "updated_at": now,
    }
    
    await collection.insert_one(new_device.copy())
    new_device.pop("_id", None)
    
    await ws_manager.broadcast({
        "event": "device_added",
        "data": {**new_device, "created_at": str(now), "updated_at": str(now)}
    })
    return {"message": "Thêm thành công", "data": new_device}


@app.put("/devices/{device_id}")
async def update_device_info(device_id: str, data: dict = Body(...)):
    collection = db.db["devices"]
    update_fields = {}
    for field in ["name", "room", "type", "icon", "is_inverted", "gpio_pin"]:
        if field in data:
            update_fields[field] = data[field]
    
    update_fields["updated_at"] = datetime.utcnow()
    await collection.update_one({"device_id": device_id}, {"$set": update_fields})
    updated = await collection.find_one({"device_id": device_id}, {"_id": 0})
    
    await ws_manager.broadcast({
        "event": "device_updated",
        "data": {**update_fields, "device_id": device_id, "updated_at": str(update_fields["updated_at"])}
    })
    return {"message": "Cập nhật thành công", "data": updated}


@app.delete("/devices/{device_id}")
async def delete_device(device_id: str):
    collection = db.db["devices"]
    await collection.delete_one({"device_id": device_id})
    await db.db["schedules"].delete_many({"device_id": device_id})
    await db.db["device_logs"].delete_many({"device_id": device_id})
    await ws_manager.broadcast({"event": "device_deleted", "data": {"device_id": device_id}})
    return {"message": "Đã xóa"}


@app.post("/device/update")
async def update_device_status(data: dict = Body(...)):
    device_id = data.get("device_id")
    status = data.get("status")
    now = datetime.utcnow()
    collection = db.db["devices"]

    await collection.update_one({"device_id": device_id}, {"$set": {"status": bool(status), "updated_at": now}})
    await db.db["device_logs"].insert_one({"device_id": device_id, "status": bool(status), "timestamp": now})

    device = await collection.find_one({"device_id": device_id})
    gpio_pin = device.get("gpio_pin")
    is_inverted = device.get("is_inverted", False)
    
    actual_status = status
    if is_inverted: actual_status = not status
        
    if gpio_pin is not None:
        topic = "smarthome/esp/gpio/control"
        payload = json.dumps({"pin": gpio_pin, "action": "on" if actual_status else "off"})
    else:
        topic = f"smarthome/devices/{device_id}/control"
        payload = "ON" if actual_status else "OFF"
        
    await mqtt.publish(topic, payload)
    await ws_manager.broadcast({
        "event": "device_update",
        "data": {"device_id": device_id, "status": bool(status)}
    })
    return {"message": "OK"}


@app.get("/sensors/latest")
async def get_latest_sensors():
    latest_sensor = await db.db["sensors"].find_one({}, {"_id": 0}, sort=[("timestamp", -1)])
    if latest_sensor: return latest_sensor
    return {"device_id": "none", "temperature": 0.0, "humidity": 0.0, "timestamp": datetime.utcnow()}


@app.get("/schedules")
async def get_schedules():
    collection = db.db["schedules"]
    schedules = await collection.find({}).to_list(100)
    for sch in schedules: sch["id"] = str(sch.pop("_id"))
    return schedules

@app.post("/schedules")
async def create_schedule(schedule: ScheduleCreate):
    collection = db.db["schedules"]
    doc = schedule.model_dump()
    doc["created_at"] = datetime.utcnow()
    result = await collection.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    # Loại bỏ ObjectId trước khi trả về để tránh lỗi serialize
    doc.pop("_id", None)
    return doc

@app.delete("/schedules/{schedule_id}")
async def delete_schedule(schedule_id: str):
    await db.db["schedules"].delete_one({"_id": ObjectId(schedule_id)})
    return {"message": "OK"}


# --- TRỢ LÝ AI (GROQ) ---
@app.post("/ai/chat")
async def ai_chat(req: ChatRequest):
    if not hasattr(settings, 'GROQ_API_KEY') or not settings.GROQ_API_KEY:
         return {"reply": "Thiếu API Key", "device_id": "none", "action": False}
    
    groq_client = AsyncGroq(api_key=settings.GROQ_API_KEY)
    all_devices = await db.db["devices"].find({}, {"_id": 0}).to_list(100)
    
    device_list = []
    for d in all_devices:
        has_fw = d["device_id"] in FIRMWARE_DEVICE_IDS or d.get("gpio_pin") is not None
        room_name = d.get("room", "N/A")
        status_text = "Ready" if has_fw else "No Pin"
        device_list.append(f'- NAME: {d["name"]}, ID: {d["device_id"]}, ROOM: {room_name}, TYPE: {d["type"]}, STATUS: {status_text}')
    
    device_list_str = "\n".join(device_list) if device_list else "None"
    
    system_prompt = f"""Bạn là 'Nhà' - Một quản gia AI Gen Z cực kỳ thông minh, cool ngầu và hiểu chuyện.
Danh sách thiết bị:
{device_list_str}

QUY TẮC ỨNG XỬ & ĐIỀU KHIỂN:
1. NGÔN NGỮ: Nói chuyện như bạn thân, dùng ngôn ngữ Gen Z (vd: 'oke nha', 'đã rõ lền', 'quá là mlem', 'đỉnh nóc kịch trần', 'đã xong ạ'). Ngắn gọn nhưng phải CHẤT.
2. THÔNG MINH ĐỘT XUẤT: Nếu người dùng nói sai ngữ pháp, nói tắt, hoặc nói tiếng Anh bồi (vd: 'light bed', 'bật cái đèn ngủ cái coi', 'tắt mẹ nó đèn đi'), bạn phải tự 'nhảy số' để tìm đúng ID thiết bị dựa trên keyword quan trọng nhất.
3. LOGIC ÁNH XẠ: Luôn ưu tiên kết hợp Tên + Phòng để ra lệnh chính xác 100%.
4. PHẢN HỒI JSON: {{"device_id": ["ID"], "action": true/false, "reply": "Lý do/Lời nhắn Gen Z"}}
ONLY RETURN JSON."""

    try:
        response = await groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "system", "content": system_prompt}, {"role": "user", "content": req.message}],
            temperature=0.3
        )
        data = json.loads(response.choices[0].message.content.replace("```json", "").replace("```", "").strip())
        
        device_ids = data.get("device_id")
        if isinstance(device_ids, str) and device_ids != "none": device_ids = [device_ids]
        elif not isinstance(device_ids, list): device_ids = []
            
        action = data.get("action")
        reply = data.get("reply", "OK")
        
        if device_ids:
            collection = db.db["devices"]
            for d_id in device_ids:
                if d_id == "none": continue
                device = await collection.find_one({"device_id": d_id})
                if device:
                    gpio_pin = device.get("gpio_pin")
                    is_inverted = device.get("is_inverted", False)
                    actual_action = not action if is_inverted else action

                    topic = "smarthome/esp/gpio/control" if gpio_pin is not None else f"smarthome/devices/{d_id}/control"
                    payload = json.dumps({"pin": gpio_pin, "action": "on" if actual_action else "off"}) if gpio_pin is not None else ("ON" if actual_action else "OFF")

                    await mqtt.publish(topic, payload)
                    await collection.update_one({"device_id": d_id}, {"$set": {"status": bool(action), "updated_at": datetime.utcnow()}})
                    await ws_manager.broadcast({"event": "device_update", "data": {"device_id": d_id, "status": bool(action)}})
            
        return {"reply": reply, "device_id": device_ids, "action": action}
    except Exception as e:
        return {"reply": f"Lỗi: {str(e)}", "device_id": "none", "action": False}