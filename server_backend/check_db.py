import motor.asyncio
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

async def check():
    client = motor.asyncio.AsyncIOMotorClient(os.getenv('MONGO_URI', 'mongodb://localhost:27017'))
    db = client['iot_database']
    
    print("\n--- [DANH SÁCH THIẾT BỊ TRONG DB] ---")
    devices = await db['devices'].find({}, {"_id": 0}).to_list(100)
    for d in devices:
        print(f"ID: {d.get('device_id')} | Tên: {d.get('name')} | Chân Pin: {d.get('gpio_pin')}")
        
    print("\n--- [DANH SÁCH LỊCH TRÌNH ĐÃ ĐẶT] ---")
    schedules = await db['schedules'].find({}, {"_id": 0}).to_list(100)
    for s in schedules:
        print(f"ID Thiết bị: {s.get('device_id')} | Giờ hẹn: {s.get('time')} | Trạng thái: {'BẬT' if s.get('action') else 'TẮT'}")
    
    print("\n-------------------------------------")

if __name__ == "__main__":
    asyncio.run(check())
