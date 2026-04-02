from fastapi import APIRouter
from datetime import datetime
from bson import ObjectId

from app.core.database import db
from app.models.schedule import ScheduleCreate

router = APIRouter()

@router.get("/schedules")
async def get_schedules():
    collection = db.db["schedules"]
    schedules = await collection.find({}).to_list(100)
    for sch in schedules: sch["id"] = str(sch.pop("_id"))
    return schedules

@router.post("/schedules")
async def create_schedule(schedule: ScheduleCreate):
    collection = db.db["schedules"]
    doc = schedule.model_dump()
    doc["created_at"] = datetime.utcnow()
    result = await collection.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc

@router.delete("/schedules/{schedule_id}")
async def delete_schedule(schedule_id: str):
    await db.db["schedules"].delete_one({"_id": ObjectId(schedule_id)})
    return {"message": "OK"}
