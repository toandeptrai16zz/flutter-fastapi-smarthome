import paho.mqtt.client as paho
import asyncio
from datetime import datetime
from app.core.config import settings


class MQTTService:
    def __init__(self):
        self.client = None
        self.task = None
        self.connected = False
        self.loop = None  # Giữ luồng chính
        self.last_ai_alert_time = 0.0 # Lưu thời điểm cảnh báo AI cuối cùng

    async def start(self):
        print(f"Connecting to MQTT Broker at {settings.MQTT_BROKER_URL}:{settings.MQTT_BROKER_PORT}...")
        self.loop = asyncio.get_event_loop()
        await self.loop.run_in_executor(None, self._connect_sync)

    def _connect_sync(self):
        try:
            self.client = paho.Client(client_id="fastapi_backend", clean_session=True)
            self.client.on_connect = self._on_connect
            self.client.on_message = self._on_message

            if settings.MQTT_USERNAME:
                self.client.username_pw_set(settings.MQTT_USERNAME, settings.MQTT_PASSWORD)

            self.client.connect(settings.MQTT_BROKER_URL, settings.MQTT_BROKER_PORT, keepalive=60)
            self.client.loop_start()
        except Exception as e:
            print(f"[WARNING] Không kết nối được MQTT Broker: {e}")
            self.connected = False

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            self.connected = True
            print("✅ Connected to MQTT Broker!")
            # Subscribe các loại topic
            client.subscribe("smarthome/devices/+/status")
            client.subscribe("smarthome/sensors/+/data")
            client.subscribe("smarthome/camera/ip")  # Hứng IP động của ESP32-CAM
        else:
            print(f"MQTT connect failed, rc={rc}")
            self.connected = False

    def _on_message(self, client, userdata, msg):
        topic = msg.topic
        payload = msg.payload.decode()
        print(f"📥 Received: {topic} = {payload}")

        # === XỬ LÝ CẢM BIẾN PIR (An ninh) ===
        if topic == "smarthome/sensors/pir/data":
            import json
            import time
            try:
                data = json.loads(payload)
                motion = data.get("motion", False)
                current_time = time.time()

                # Chỉ kích hoạt AI Security khi PIR phát hiện chuyển động + cooldown 120s
                if motion and (current_time - self.last_ai_alert_time > 120):
                    self.last_ai_alert_time = current_time

                    async def process_security_ai():
                        from groq import AsyncGroq
                        from app.services.websocket_manager import ws_manager
                        try:
                            if not settings.GROQ_API_KEY:
                                raise ValueError("Chưa cài GROQ_API_KEY")
                            groq_client = AsyncGroq(api_key=settings.GROQ_API_KEY)
                            now_hour = datetime.now().hour
                            prompt = f'''Bạn là AI An Ninh. Hiện tại là {now_hour} giờ. Cảm biến hồng ngoại phát hiện có chuyển động lạ trong nhà!
Nếu là ban đêm (22h - 5h sáng), hãy bật báo động còi và báo tin khẩn cấp. Nếu là ban ngày, chỉ báo tin bình thường.
Trả về JSON duy nhất: {{"is_threat": true/false, "action": "turn_on_lights", "message": "Thông báo Push Notification bằng giọng văn cảnh sát hoặc quản gia bảo vệ"}}'''
                            response = await groq_client.chat.completions.create(
                                model="llama-3.3-70b-versatile",
                                messages=[{"role": "user", "content": prompt}],
                                temperature=0.2
                            )
                            result_text = response.choices[0].message.content.replace("```json", "").replace("```", "").strip()
                            ai_result = json.loads(result_text)

                            print(f"🚨 AI Security Alert: {ai_result.get('message')}")
                            if ai_result.get("is_threat"):
                                await self.publish("smarthome/devices/den_phong_khach/control", "ON")
                                await self.publish("smarthome/camera/flash", "ON")

                            # ✅ FIX: alert_type = "security" → Flutter hiển thị Push Notification
                            await ws_manager.broadcast({
                                "type": "ai_alert",
                                "message": ai_result.get("message", "Phát hiện đột nhập!"),
                                "alert_type": "security"
                            })
                        except Exception as ai_e:
                            print(f"❌ Lỗi AI Security: {ai_e}")

                    if self.loop is not None and self.loop.is_running():
                        asyncio.run_coroutine_threadsafe(process_security_ai(), self.loop)
            except Exception as e:
                print(f"❌ Lỗi xử lý PIR: {e}")

        # === XỬ LÝ CẢM BIẾN NHIỆT ĐỘ/ĐỘ ẨM (DHT) ===
        elif topic == "smarthome/sensors/dht11/data":
            import json
            import time
            from app.core.database import db
            try:
                data = json.loads(payload)
                sensor_id = topic.split("/")[2]
                temp = data.get("temperature", 0.0)
                hum = data.get("humidity", 0.0)
                current_time = time.time()

                # --- AI INTERVENTION: TỰ ĐỘNG LÀM MÁT khi nhiệt độ >= 31°C ---
                if temp >= 31.0 and (current_time - self.last_ai_alert_time > 600):
                    self.last_ai_alert_time = current_time

                    async def process_ai():
                        from groq import AsyncGroq
                        from app.services.websocket_manager import ws_manager
                        try:
                            if not settings.GROQ_API_KEY:
                                raise ValueError("Chưa cài GROQ_API_KEY trong .env")
                            groq_client = AsyncGroq(api_key=settings.GROQ_API_KEY)
                            prompt = f"""Nhiệt độ trong nhà hiện tại là {temp}°C, độ ẩm {hum}%.
Bạn là trợ lý AI quản gia nhà thông minh. Thời tiết đang nóng (trên 31 độ), hãy quyết định BẬT quạt.
Tạo câu thông báo ngắn gọn bằng tiếng Việt vui vẻ thân thiện (dưới 15 chữ).
Trả về ĐÚNG 1 JSON, KHÔNG markdown: {{"fan_action": true, "message": "Câu thông báo"}}"""
                            response = await groq_client.chat.completions.create(
                                model="llama-3.3-70b-versatile",
                                messages=[{"role": "user", "content": prompt}],
                                temperature=0.3
                            )
                            result_text = response.choices[0].message.content.replace("```json", "").replace("```", "").strip()
                            ai_result = json.loads(result_text)
                            if ai_result.get("fan_action"):
                                print(f"🤖 AI Groq quyết định bật quạt: {ai_result.get('message')}")
                                await self.publish("smarthome/devices/fan_1/control", "ON")
                                # ✅ FIX: alert_type = "info" → Flutter hiển thị Dialog (không phải push notif)
                                await ws_manager.broadcast({
                                    "type": "ai_alert",
                                    "message": ai_result.get("message", "Nóng quá! AI bật Quạt cho bạn nha! 🌀"),
                                    "device_id": "fan_1",
                                    "status": True,
                                    "alert_type": "info"
                                })
                        except Exception as ai_e:
                            print(f"❌ Lỗi AI Groq tự động làm mát: {ai_e}")
                            from app.services.websocket_manager import ws_manager
                            await ws_manager.broadcast({
                                "type": "ai_alert",
                                "message": f"Lỗi AI: {ai_e}",
                                "device_id": "fan_1",
                                "status": False,
                                "alert_type": "info"
                            })

                    if self.loop is not None and self.loop.is_running():
                        asyncio.run_coroutine_threadsafe(process_ai(), self.loop)

                # --- LƯU DB + BROADCAST SENSOR ---
                async def save_and_broadcast_sensor():
                    if db.db is not None:
                        await db.db["sensors"].insert_one({
                            "device_id": sensor_id,
                            "temperature": temp,
                            "humidity": hum,
                            "timestamp": datetime.utcnow()
                        })
                        print(f"✅ Lưu DB thành công cảm biến {sensor_id}: {data}")
                    from app.services.websocket_manager import ws_manager
                    await ws_manager.broadcast({
                        "type": "sensor",
                        "temperature": temp,
                        "humidity": hum
                    })
                    print(f"📡 Đã phát broadcast cảm biến {sensor_id} tới WebSocket")

                if self.loop is not None and self.loop.is_running():
                    asyncio.run_coroutine_threadsafe(save_and_broadcast_sensor(), self.loop)
                else:
                    print("⚠️ Event loop chưa sẵn sàng, bỏ qua lưu DB")
            except Exception as e:
                print(f"❌ Lỗi xử lý data cảm biến: {e}")

        # === XỬ LÝ TRẠNG THÁI THIẾT BỊ TỪ NÚT BẤM VẬT LÝ TRÊN ESP32 ===
        elif topic.startswith("smarthome/devices/") and topic.endswith("/status"):
            try:
                import json
                from app.services.websocket_manager import ws_manager
                device_data = json.loads(payload)

                async def broadcast_device_status():
                    from app.core.database import db
                    if db.db is not None:
                        collection = db.db["devices"]
                        all_devices = await collection.find({}).to_list(100)

                        # Map relay → GPIO pin (theo phần cứng NodeMCU)
                        relay_gpio_map = {
                            "relay1": 13,  # D7
                            "relay2": 12,  # D6
                        }

                        for relay_key, gpio_pin in relay_gpio_map.items():
                            physical_state = device_data.get(relay_key)
                            if physical_state is None:
                                continue

                            for device in all_devices:
                                if device.get("gpio_pin") == gpio_pin:
                                    logical_status = not physical_state if device.get("is_inverted") else physical_state
                                    await collection.update_one(
                                        {"device_id": device["device_id"]},
                                        {"$set": {"status": logical_status, "updated_at": datetime.utcnow()}}
                                    )
                                    await db.db["device_logs"].insert_one({
                                        "device_id": device["device_id"],
                                        "status": logical_status,
                                        "source": "physical_button",
                                        "timestamp": datetime.utcnow()
                                    })
                                    await ws_manager.broadcast({
                                        "event": "device_update",
                                        "data": {"device_id": device["device_id"], "status": logical_status}
                                    })
                                    print(f"🔘 Nút bấm vật lý: {device['device_id']} → {logical_status}")
                                    break

                if self.loop is not None and self.loop.is_running():
                    asyncio.run_coroutine_threadsafe(broadcast_device_status(), self.loop)
            except Exception as e:
                print(f"❌ Lỗi broadcast device status: {e}")

        # === LƯU IP ĐỘNG CỦA ESP32-CAM ===
        elif topic == "smarthome/camera/ip":
            print(f"📸 NHẬN ĐƯỢC IP CAMERA TỪ MQTT: {payload}")
            try:
                import json
                from app.core.database import db
                cam_data = json.loads(payload)
                ip_address = cam_data.get("ip")
                if ip_address and db.db is not None:
                    async def save_cam_ip():
                        # ✅ FIX: datetime đã được import ở đầu file, không còn lỗi NameError
                        await db.db["settings"].update_one(
                            {"type": "camera_config"},
                            {"$set": {"ip": ip_address, "updated_at": datetime.utcnow()}},
                            upsert=True
                        )
                        print(f"📸 Cập nhật IP ESP32-CAM thành công: {ip_address}")

                    if self.loop is not None and self.loop.is_running():
                        asyncio.run_coroutine_threadsafe(save_cam_ip(), self.loop)
            except Exception as e:
                print(f"❌ Lỗi lưu IP Camera: {e}")

    async def publish(self, topic: str, payload: str):
        if not self.client or not self.connected:
            print(f"⚠️ MQTT chưa kết nối, thử kết nối lại trước khi publish: {topic}")
            await self.start()  # Thử reconnect nhanh

        if self.client and self.connected:
            try:
                info = self.client.publish(topic, payload, qos=1)  # QoS 1: đảm bảo gửi ít nhất 1 lần
                info.wait_for_publish(timeout=2)
                print(f"📤 Published to {topic}: {payload}")
                return True
            except Exception as e:
                print(f"❌ Lỗi khi publish MQTT: {e}")

        print(f"❌ Không thể gửi lệnh tới {topic}")
        return False


mqtt = MQTTService()
