# Hướng Dẫn Cài Đặt MongoDB

---

## Cách 1: Cài MongoDB Community Server (Khuyến nghị)

### Bước 1: Tải MongoDB
Vào trang: https://www.mongodb.com/try/download/community

Chọn:
- **Version:** 7.0 (Latest)
- **Platform:** Windows
- **Package:** `msi`

Bấm **Download** và chạy file `.msi` vừa tải.

### Bước 2: Cài đặt
1. Chạy file cài đặt → **Next** → **Complete**
2. Chọn **"Install MongoDB as a Service"**  (để MongoDB tự khởi động cùng Windows)
3. Bỏ chọn **"Install MongoDB Compass"** nếu không cần GUI
4. Nhấn **Install** và đợi hoàn thành

### Bước 3: Kiểm tra MongoDB đã chạy chưa

Mở **PowerShell** hoặc **CMD** gõ:
```powershell
mongosh
```
Nếu thấy dấu nhắc lệnh `test>` là **thành công**! 

Hoặc kiểm tra qua Services:
1. Nhấn `Win + R` → gõ `services.msc`
2. Tìm service **"MongoDB"** → đảm bảo Status là **"Running"**

---

## Cách 2: Dùng Docker (Không cần cài đặt)

Nếu bạn đã có Docker Desktop:
```bash
docker run -d -p 27017:27017 --name mongodb mongo:7
```
Xong! MongoDB sẽ chạy ở `localhost:27017`.

---

## Kết Nối Dự Án Với MongoDB

### Bước 1: Cập nhật file `.env`

Mở file `server_backend/.env`:
```env
MONGODB_URL=mongodb://localhost:27017
MQTT_BROKER_URL=broker.hivemq.com
MQTT_BROKER_PORT=1883
```

### Bước 2: Khởi động MongoDB

**Nếu cài bằng MSI (Service tự chạy):**
```powershell
# Kiểm tra trạng thái
Get-Service -Name MongoDB

# Nếu chưa chạy, khởi động thủ công:
Start-Service -Name MongoDB
```

**Nếu dùng Docker:**
```bash
docker start mongodb
```

### Bước 3: Khôi phục kết nối MongoDB trong Backend

Mở file `server_backend/app/main.py` và đảm bảo phần kết nối MongoDB được bật. Hiện tại dự án đang chạy ở chế độ **In-Memory** (không cần MongoDB), để bật lại MongoDB thì liên hệ trợ giảng hoặc thêm lại đoạn:

```python
from app.core.database import connect_to_mongo, close_mongo_connection, db
```

### Bước 4: Cài thư viện Python cần thiết
```bash
cd server_backend
venv\Scripts\pip.exe install motor pymongo
```

### Bước 5: Chạy lại Server
```bash
venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Nếu thấy log:
```
Connected to MongoDB!
 Connected to MQTT Broker!
Uvicorn running on http://0.0.0.0:8000
```
→ **Hệ thống đã hoạt động đầy đủ với Database!** 🎉

---

## Xem Dữ Liệu Trong MongoDB

### Dùng MongoDB Compass (GUI)
1. Tải tại: https://www.mongodb.com/try/download/compass
2. Kết nối: `mongodb://localhost:27017`
3. Chọn database **"smarthome_db"** → Collection **"devices"**

### Dùng mongosh (Command line)
```bash
mongosh
use smarthome_db
db.devices.find().pretty()
```

Kết quả mẫu:
```json
[
  {
    "_id": "...",
    "device_id": "led_1",
    "name": "Device led_1",
    "status": true,
    "value": 0
  },
  {
    "_id": "...",
    "device_id": "led_2",
    "name": "Device led_2",
    "status": false,
    "value": 0
  }
]
```

---

> **Lưu ý:** Trong giai đoạn phát triển và demo, dự án có thể chạy ở chế độ In-Memory (không cần MongoDB). MongoDB chỉ cần thiết khi muốn **lưu trữ lịch sử** và dữ liệu **bền vững sau khi tắt server**.
