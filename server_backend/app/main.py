from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
# from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Cấu hình CORS (Để App và Web không bị chặn khi gọi API)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Cho phép tất cả (iPhone, Web, ESP...) truy cập
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- DATABASE TẠM THỜI (Lưu trong RAM) ---
# Mặc định đèn led_1 đang TẮT (False)
fake_db = {
    "led_1": {"status": False}
}

# --- ĐỊNH NGHĨA DỮ LIỆU GỬI LÊN ---
class DeviceUpdate(BaseModel):
    device_id: str
    status: bool

# --- API 1: KIỂM TRA SERVER 
@app.get("/")
def read_root():
    return {"message": "IoT Server đang chạy ngon lành!"}

# --- API 2: LẤY TRẠNG THÁI (Cho ESP8266 và App cập nhật giao diện) ---
@app.get("/device/{device_id}")
def get_device_status(device_id: str):
    if device_id not in fake_db:
        # Nếu chưa có thì tạo mới mặc định là Tắt
        fake_db[device_id] = {"status": False}
    return fake_db[device_id]

# --- API 3: CẬP NHẬT TRẠNG THÁI (Cho App gửi lệnh Bật/Tắt) ---
@app.post("/device/update")
def update_device_status(data: DeviceUpdate):
    # Cập nhật vào database
    fake_db[data.device_id] = {"status": data.status}
    
    # In ra log để bạn nhìn thấy
    print(f"👉 LỆNH MỚI: Thiết bị {data.device_id} chuyển sang {data.status}")
    
    return {"message": "Cập nhật thành công", "current_status": fake_db[data.device_id]}