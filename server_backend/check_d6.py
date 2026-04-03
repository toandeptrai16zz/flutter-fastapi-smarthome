import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

async def main():
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    db = client["smarthome_db"]
    devices = await db["devices"].find({}, {"_id": 0}).to_list(100)
    for d in devices:
        print(f"ID: {d.get('device_id')}, Name: {d.get('name')}, Pin: {d.get('gpio_pin')}, Inverted: {d.get('is_inverted')}, Status: {d.get('status')}, Room: {d.get('room')}")

asyncio.run(main())
