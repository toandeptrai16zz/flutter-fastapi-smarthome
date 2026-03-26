from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class ScheduleCreate(BaseModel):
    device_id: str
    action: bool # True = Bật, False = Tắt
    time: str # Thời gian dạng "HH:MM", ví dụ "08:30"
    repeated_days: List[str] = Field(default_factory=list) # Ví dụ: ["T2", "T3"], nếu rỗng là chỉ chạy 1 lần
    is_active: bool = True

class ScheduleResponse(BaseModel):
    id: str
    device_id: str
    action: bool
    time: str
    repeated_days: List[str]
    is_active: bool 
    created_at: datetime
