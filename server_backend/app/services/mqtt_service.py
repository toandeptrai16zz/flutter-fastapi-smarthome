import paho.mqtt.client as paho
import asyncio
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
            # Subscribe 2 loại topic: lệnh cho thiết bị (status) và dữ liệu cảm biến (data)
            client.subscribe("smarthome/devices/+/status")
            client.subscribe("smarthome/sensors/+/data")
        else:
            print(f"MQTT connect failed, rc={rc}")
            self.connected = False

    def _on_message(self, client, userdata, msg):
        topic = msg.topic
        payload = msg.payload.decode()
        print(f"📥 Received: {topic} = {payload}")
        
        # Nếu nhận dữ liệu từ cảm biến
        if topic.startswith("smarthome/sensors/"):
            import json
            import time
            from datetime import datetime
            from app.core.database import db
            from app.main import ws_manager
            try:
                data = json.loads(payload)
                sensor_id = topic.split("/")[2]
                temp = data.get("temperature", 0.0)
                hum = data.get("humidity", 0.0)

                # KIỂM TRA NHIỆT ĐỘ CÓ QUÁ NÓNG (>=31 ĐỘ C) ĐỂ GỌI AI
                current_time = time.time()
                if temp >= 31.0 and (current_time - self.last_ai_alert_time > 10):  # 10s = Test mode (Đổi về 600s sau)
                    self.last_ai_alert_time = current_time
                    async def process_ai():
                        import google.generativeai as genai
                        from app.core.config import settings
                        from app.services.websocket_manager import ws_manager
                        try:
                            if not settings.GEMINI_API_KEY:
                                raise ValueError("Missing GEMINI_API_KEY in settings")
                            genai.configure(api_key=settings.GEMINI_API_KEY)
                            model = genai.GenerativeModel('gemini-2.5-flash', generation_config={"response_mime_type": "application/json"})
                            prompt = f"""
Nhiệt độ hiện tại trong nhà là {temp}°C, độ ẩm {hum}%.
Hãy đóng vai một trợ lý AI quản gia thông minh.
Vì thời tiết đang khá nóng (trên 31 độ), hãy quyết định BẬT 'Quạt Máy' (thiết lập fan_action là true).
Đồng thời, tạo một câu thông báo ngắn gọn bằng tiếng Việt vui vẻ, thân thiện (dưới 15 chữ) cho người dùng biết bạn vừa tự bật quạt giúp họ làm mát.
Đáp ứng đúng JSON duy nhất như sau: {{"fan_action": true, "message": "Câu thông báo"}}
"""
                            # Tránh block main loop
                            response = await asyncio.to_thread(model.generate_content, prompt)
                            result_text = response.text.strip()
                            if result_text.startswith("```json"):
                                result_text = result_text[7:-3]
                            ai_result = json.loads(result_text)
                            if ai_result.get("fan_action"):
                                print(f"🤖 AI quyết định bật quạt: {ai_result.get('message')}")
                                await self.publish("smarthome/devices/fan_1/control", "ON")
                                await ws_manager.broadcast({
                                    "type": "ai_alert",
                                    "message": ai_result.get("message", "Nóng quá! Nhỏ AI bật Quạt cho anh nha!"),
                                    "device_id": "fan_1",
                                    "status": True
                                })
                        except Exception as ai_e:
                            print(f"❌ Lỗi xử lý AI Tự động làm mát: {ai_e}")
                            await ws_manager.broadcast({
                                "type": "ai_alert",
                                "message": f"Lỗi AI Backend: {ai_e}",
                                "device_id": "fan_1",
                                "status": False
                            })

                    if self.loop is not None and self.loop.is_running():
                        asyncio.run_coroutine_threadsafe(process_ai(), self.loop)

                async def save_and_broadcast_sensor():
                    # 1. Lưu MongoDB
                    if db.db is not None:
                        await db.db["sensors"].insert_one({
                            "device_id": sensor_id,
                            "temperature": temp,
                            "humidity": hum,
                            "timestamp": datetime.utcnow()
                        })
                        print(f"✅ Lưu DB thành công cảm biến {sensor_id}: {data}")
                    # 2. Broadcast realtime qua WebSocket tới tất cả Flutter clients
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

        # Nếu nhận trạng thái thiết bị từ ESP32
        elif topic.startswith("smarthome/devices/") and topic.endswith("/status"):
            try:
                import json
                from app.services.websocket_manager import ws_manager
                device_data = json.loads(payload)
                async def broadcast_device_status():
                    await ws_manager.broadcast({
                        "type": "esp32_status",
                        "relay1": device_data.get("relay1", False),
                        "relay2": device_data.get("relay2", False),
                        "relay3": device_data.get("relay3", False),
                        "relay4": device_data.get("relay4", False),
                        "online": device_data.get("online", False)
                    })
                if self.loop is not None and self.loop.is_running():
                    asyncio.run_coroutine_threadsafe(broadcast_device_status(), self.loop)
            except Exception as e:
                print(f"❌ Lỗi broadcast device status: {e}")

    async def publish(self, topic: str, payload: str):
        if not self.client or not self.connected:
            print(f"⚠️ MQTT chưa kết nối, thử kết nối lại trước khi publish: {topic}")
            await self.start() # Thử reconnect nhanh
            
        if self.client and self.connected:
            try:
                info = self.client.publish(topic, payload, qos=1) # Dùng QoS 1 cho chắc chắn
                info.wait_for_publish(timeout=2) # Chờ tối đa 2s
                print(f"📤 Published to {topic}: {payload}")
                return True
            except Exception as e:
                print(f"❌ Lỗi khi publish MQTT: {e}")
        
        print(f"❌ Không thể gửi lệnh tới {topic}")
        return False


mqtt = MQTTService()
