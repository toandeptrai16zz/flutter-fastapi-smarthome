import paho.mqtt.client as paho
import asyncio
from app.core.config import settings


class MQTTService:
    def __init__(self):
        self.client = None
        self.task = None
        self.connected = False
        self.loop = None  # Giữ luồng chính

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
            from datetime import datetime
            from app.core.database import db
            from app.main import ws_manager
            try:
                data = json.loads(payload)
                sensor_id = topic.split("/")[2]
                
                async def save_and_broadcast_sensor():
                    # 1. Lưu MongoDB
                    if db.db is not None:
                        await db.db["sensors"].insert_one({
                            "device_id": sensor_id,
                            "temperature": data.get("temperature", 0.0),
                            "humidity": data.get("humidity", 0.0),
                            "timestamp": datetime.utcnow()
                        })
                        print(f"✅ Lưu DB thành công cảm biến {sensor_id}: {data}")
                    # 2. Broadcast realtime qua WebSocket tới tất cả Flutter clients
                    from app.services.websocket_manager import ws_manager
                    await ws_manager.broadcast({
                        "type": "sensor",
                        "temperature": data.get("temperature", 0.0),
                        "humidity": data.get("humidity", 0.0)
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
