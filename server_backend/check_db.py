import asyncio
import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()

async def check_db():
    mongo_url = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    db_name = os.getenv("MONGODB_DB_NAME", "smarthome_db")
    client = AsyncIOMotorClient(mongo_url)
    db = client[db_name]
    
    settings = await db["settings"].find_one({"type": "camera_config"})
    print(f"--- Camera Config ---")
    print(settings)
    
    devices = await db["devices"].find_one({"device_id": "den_phong_khach"})
    print(f"--- Example Device (den_phong_khach) ---")
    print(devices)
    
    client.close()

if __name__ == "__main__":
    asyncio.run(check_db())
