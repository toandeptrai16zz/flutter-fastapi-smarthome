import asyncio
from datetime import datetime
import json
from app.core.database import db
from app.services.mqtt_service import mqtt
from app.services.websocket_manager import ws_manager

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
            
            if schedules:
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
