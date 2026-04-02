from fastapi import APIRouter, HTTPException, Body
from typing import List
from datetime import datetime
import json

from app.core.database import db
from app.core.config import settings
from app.services.mqtt_service import mqtt
from app.services.websocket_manager import ws_manager

router = APIRouter()

FIRMWARE_DEVICE_IDS = ["led_1", "led_2", "fan_1", "den_ngu", "den_phong_khach"]

@router.get("/devices")
async def get_all_devices():
    collection = db.db["devices"]
    devices = await collection.find({}, {"_id": 0}).to_list(100)
    for d in devices:
        d["has_firmware"] = d["device_id"] in FIRMWARE_DEVICE_IDS or d.get("gpio_pin") is not None
        if d.get("gpio_pin") is not None:
            for label, pin in settings.ESP32_PIN_MAP.items():
                if pin == d["gpio_pin"]:
                    d["pin_label"] = label
                    break
    return devices

@router.get("/devices/available-pins")
async def get_available_pins():
    collection = db.db["devices"]
    used_pins = await collection.distinct("gpio_pin")
    used_pins = [p for p in used_pins if p is not None]
    
    # Các chân cứng (Hardware Pins) đã gắn cảm biến/nút
    hardcoded_pins = [5, 4, 0, 2] # D1, D2, D3(Nút 1), D4(Nút 2)

    available = []
    for label, pin in settings.ESP32_PIN_MAP.items():
        is_used_by_db = pin in used_pins
        is_hardcoded = pin in hardcoded_pins
        available.append({
            "label": label,
            "pin": pin,
            "is_used": is_used_by_db or is_hardcoded
        })
    return available

@router.post("/devices")
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

@router.put("/devices/{device_id}")
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

@router.delete("/devices/{device_id}")
async def delete_device(device_id: str):
    collection = db.db["devices"]
    await collection.delete_one({"device_id": device_id})
    await db.db["schedules"].delete_many({"device_id": device_id})
    await db.db["device_logs"].delete_many({"device_id": device_id})
    await ws_manager.broadcast({"event": "device_deleted", "data": {"device_id": device_id}})
    return {"message": "Đã xóa"}

@router.post("/device/update")
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

@router.get("/camera/status")
async def get_camera_status():
    cam_config = await db.db["settings"].find_one({"type": "camera_config"}, {"_id": 0})
    if cam_config and cam_config.get("ip"):
        return {"success": True, "ip": cam_config["ip"], "url": f"http://{cam_config['ip']}:81/stream"}
    return {"success": False, "message": "Chưa có dữ liệu IP Camera"}

@router.post("/camera/flash")
async def control_camera_flash(data: dict = Body(...)):
    action = data.get("action", "off")  # "on" hoặc "off"
    await mqtt.publish("smarthome/camera/flash", action.upper())
    return {"message": f"Flash {action}", "success": True}

@router.get("/sensors/latest")
async def get_latest_sensors():
    latest_sensor = await db.db["sensors"].find_one({}, {"_id": 0}, sort=[("timestamp", -1)])
    if latest_sensor: return latest_sensor
    return {"device_id": "none", "temperature": 0.0, "humidity": 0.0, "timestamp": datetime.utcnow()}
