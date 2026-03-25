"""
Script khởi tạo MongoDB cho dự án IoT SmartHome.
Chạy 1 lần duy nhất: python init_db.py
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime

MONGO_URL = "mongodb://localhost:27017"
DB_NAME = "smarthome_db"

# ---- Dữ liệu mẫu ban đầu ----
INITIAL_DEVICES = [
    {
        "device_id": "led_1",
        "name": "Đèn Phòng Khách",
        "type": "led",
        "room": "Phòng Khách",
        "pin": "D2",
        "status": False,
        "value": 0.0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    },
    {
        "device_id": "led_2",
        "name": "Đèn Phòng Ngủ",
        "type": "led",
        "room": "Phòng Ngủ",
        "pin": "D5",
        "status": False,
        "value": 0.0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    },
]


async def init():
    print(f"Connecting to MongoDB at {MONGO_URL}...")
    client = AsyncIOMotorClient(MONGO_URL)
    db = client[DB_NAME]

    # ── 1. Collection: devices ──────────────────────────────────────────────
    devices_col = db["devices"]
    # Tạo unique index trên device_id
    await devices_col.create_index("device_id", unique=True)
    print("✅ Index 'device_id' trên collection 'devices' đã sẵn sàng.")

    # Chèn thiết bị mẫu nếu chưa có
    for device in INITIAL_DEVICES:
        existing = await devices_col.find_one({"device_id": device["device_id"]})
        if not existing:
            await devices_col.insert_one(device)
            print(f"   ➕ Đã thêm thiết bị: {device['device_id']} - {device['name']}")
        else:
            print(f"   ✔  Thiết bị '{device['device_id']}' đã tồn tại, bỏ qua.")

    # ── 2. Collection: device_logs ──────────────────────────────────────────
    logs_col = db["device_logs"]
    # Index để query nhanh theo device_id và thời gian
    await logs_col.create_index([("device_id", 1), ("timestamp", -1)])
    print("✅ Index trên collection 'device_logs' đã sẵn sàng.")

    # ── 3. Collection: sensors (mở rộng tương lai) ─────────────────────────
    sensors_col = db["sensors"]
    await sensors_col.create_index([("device_id", 1), ("timestamp", -1)])
    print("✅ Index trên collection 'sensors' đã sẵn sàng.")

    # ── Tóm tắt ────────────────────────────────────────────────────────────
    print("\n📦 Cấu trúc Database đã được khởi tạo:")
    print(f"   Database  : {DB_NAME}")
    print(f"   Collection: devices      — Trạng thái thiết bị")
    print(f"   Collection: device_logs  — Lịch sử bật/tắt")
    print(f"   Collection: sensors      — Dữ liệu cảm biến (mở rộng)")

    collections = await db.list_collection_names()
    print(f"\n✅ Các collections hiện có: {collections}")
    client.close()
    print("\n🎉 Khởi tạo hoàn tất!")


if __name__ == "__main__":
    asyncio.run(init())
