from pydantic import BaseModel

class DeviceStatus(BaseModel):
    device_id: str
    status: bool
    message: str = None