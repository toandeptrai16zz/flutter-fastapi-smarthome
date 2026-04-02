import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

async def debug_mongo():
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    dbs = await client.list_database_names()
    print(f"Databases: {dbs}")
    
    for db_name in dbs:
        if db_name in ["admin", "local", "config"]: continue
        db = client[db_name]
        cols = await db.list_collection_names()
        print(f"  DB: {db_name} -> Collections: {cols}")
        for col_name in cols:
            count = await db[col_name].count_documents({})
            print(f"    Col: {col_name} -> Count: {count}")
            if col_name == "settings":
                doc = await db[col_name].find_one({"type": "camera_config"})
                print(f"      Camera Config: {doc}")
            if col_name == "devices":
                doc = await db[col_name].find_one({})
                print(f"      Sample Device: {doc}")

    client.close()

if __name__ == "__main__":
    asyncio.run(debug_mongo())
