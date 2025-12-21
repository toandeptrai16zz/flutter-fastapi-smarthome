from pydantic import BaseModel

# Khuôn mẫu cho lệnh cập nhật trạng thái
class DeviceUpdate(BaseModel):
    device_id: str
    status: bool  # True = Bật, False = Tắt