from fastapi import APIRouter
from datetime import datetime
from bson import ObjectId
from fastapi import HTTPException

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

@router.put("/schedules/{schedule_id}/toggle")
async def toggle_schedule(schedule_id: str):
    """Bật/tắt trạng thái is_active của lịch trình"""
    collection = db.db["schedules"]
    item = await collection.find_one({"_id": ObjectId(schedule_id)})
    if not item:
        raise HTTPException(status_code=404, detail="Không tìm thấy lịch trình")
    new_status = not item.get("is_active", True)
    await collection.update_one(
        {"_id": ObjectId(schedule_id)},
        {"$set": {"is_active": new_status}}
    )
    return {"message": "Đã đổi trạng thái", "is_active": new_status}
