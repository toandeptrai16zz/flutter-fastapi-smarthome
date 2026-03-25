from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class DeviceBase(BaseModel):
    name: str
    type: str  # e.g., "led", "sensor"
    status: bool = False
    value: Optional[float] = None
    last_updated: datetime = Field(default_factory=datetime.utcnow)

class DeviceCreate(DeviceBase):
    device_id: str

class DeviceUpdate(BaseModel):
    status: Optional[bool] = None
    value: Optional[float] = None

class DeviceInDB(DeviceBase):
    device_id: str