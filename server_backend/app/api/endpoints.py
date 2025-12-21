from fastapi import APIRouter, HTTPException
from app.models.request import DeviceUpdate
from app.models.device import DeviceStatus

router = APIRouter()

# Giả lập Database trong RAM (Lưu ý: Mất dữ liệu khi tắt server)
fake_db = {
    "led_1": False, # Mặc định đèn tắt
    "fan_1": False
}

# API 1: Lấy trạng thái thiết bị (Cho ESP32 và App poll)
@router.get("/device/{device_id}", response_model=DeviceStatus)
async def get_device_status(device_id: str):
    if device_id in fake_db:
        return {
            "device_id": device_id, 
            "status": fake_db[device_id],
            "message": "Success"
        }
    raise HTTPException(status_code=404, detail="Thiết bị không tồn tại")

# API 2: Cập nhật trạng thái (App gửi lệnh vào đây)
@router.post("/device/update", response_model=DeviceStatus)
async def update_device_status(request: DeviceUpdate):
    if request.device_id in fake_db:
        # Cập nhật vào DB giả
        fake_db[request.device_id] = request.status
        
        return {
            "device_id": request.device_id,
            "status": fake_db[request.device_id],
            "message": "Cập nhật thành công"
        }
    raise HTTPException(status_code=404, detail="Thiết bị không tồn tại")