import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime

async def force_cam_ip():
    client = AsyncIOMotorClient('mongodb://localhost:27017')
    db = client['smarthome_db']
    res = await db['settings'].update_one(
        {'type': 'camera_config'}, 
        {'$set': {'ip': '192.168.0.118', 'updated_at': datetime.utcnow()}}, 
        upsert=True
    )
    print(f"Force set Camera IP result: {res.modified_count} modified, {res.upserted_id} upserted")
    client.close()

if __name__ == "__main__":
    asyncio.run(force_cam_ip())
