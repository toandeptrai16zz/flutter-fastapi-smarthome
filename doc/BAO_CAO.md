# BÁO CÁO DỰ ÁN: IoT SmartHome System
> **Môn học:** Lập trình ứng dụng Android  
> **Công nghệ:** Flutter · FastAPI · MQTT · MongoDB · ESP8266  
> **Ngày hoàn thành:** 25/03/2026

---

## 1. Tổng Quan Hệ Thống

Dự án xây dựng một hệ thống IoT điều khiển thiết bị nhà thông minh theo mô hình 3 tầng:

```
[Flutter App] ──HTTP──▶ [FastAPI Backend] ──MQTT──▶ [ESP8266 + LED]
                               │
                          [MongoDB]
```

| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Mobile App | Flutter (Dart) | Giao diện điều khiển |
| Backend Server | FastAPI (Python) | API + MQTT Publisher |
| Database | MongoDB | Lưu trạng thái thiết bị |
| Thiết bị IoT | ESP8266 + PubSubClient | Nhận lệnh, điều khiển LED |
| Message Broker | HiveMQ (Public) | Trung gian MQTT |

---

## 2. Kiến Trúc Chi Tiết

### 2.1. Luồng Điều Khiển

```
1. User bấm nút trên App
2. Flutter gọi POST /device/update lên FastAPI
3. FastAPI lưu trạng thái vào MongoDB
4. FastAPI publish MQTT message lên topic:
       smarthome/devices/{device_id}/control
5. HiveMQ Broker nhận và forward tới ESP8266
6. ESP8266 nhận message → điều khiển chân GPIO
7. LED bật/tắt theo lệnh
```

### 2.2. Giao Thức Lựa Chọn

**Tại sao chọn MQTT thay vì HTTP Polling?**

| Tiêu chí | HTTP Polling | MQTT |
|---|---|---|
| Độ trễ | Cao (200–500ms) | Thấp (<50ms) |
| Điện năng ESP8266 | Tiêu hao nhiều | Tiết kiệm |
| Kết nối liên tục | Không | Có (Persistent) |
| Phù hợp IoT | ❌ | ✅ |

**Tại sao chọn MongoDB thay vì SQL?**

- Cấu trúc JSON linh hoạt → Phù hợp lưu trữ dữ liệu cảm biến đa dạng
- Không cần định nghĩa schema cứng → Dễ thêm loại thiết bị mới
- Tích hợp tốt với FastAPI qua thư viện `motor` (async)
- Phổ biến trong hệ sinh thái IoT/Web hiện đại

---

## 3. Cấu Trúc Thư Mục

```
IoT_SmartHome_Project/
├── client_app/                    # Flutter App
│   └── lib/
│       ├── screens/
│       │   ├── auth/
│       │   │   └── login_screen.dart
│       │   └── home/
│       │       └── dashboard_screen.dart  ← Điều khiển LED
│       ├── services/
│       │   └── api_service.dart           ← Gọi HTTP API
│       └── utils/
│           └── constants.dart             ← Base URL
│
├── server_backend/                # FastAPI Backend
│   ├── app/
│   │   ├── main.py                ← API Endpoints
│   │   ├── core/
│   │   │   ├── config.py          ← Cấu hình từ .env
│   │   │   └── database.py        ← Kết nối MongoDB
│   │   ├── models/
│   │   │   └── device.py          ← Pydantic Model
│   │   └── services/
│   │       └── mqtt_service.py    ← MQTT Publisher
│   ├── .env                       ← Biến môi trường (không commit)
│   └── requirements.txt
│
├── firmware_esp32/                # ESP8266 Firmware
│   ├── platformio.ini
│   └── src/
│       └── main.cpp               ← Arduino code MQTT
│
└── doc/
    └── BAO_CAO.md                 ← File này
```

---

## 4. Cơ Sở Dữ Liệu: MongoDB

### 4.1. Lý Do Chọn MongoDB (NoSQL)

MongoDB là hệ quản trị cơ sở dữ liệu NoSQL theo dạng Document (JSON). Với dự án IoT, đây là lựa chọn tối ưu vì:

1. **Lưu trữ dạng JSON:** Dữ liệu từ cảm biến thường là JSON không đồng nhất, MongoDB lưu trực tiếp không cần chuyển đổi.
2. **Linh hoạt schema:** Có thể thêm field mới (nhiệt độ, độ ẩm, v.v...) mà không cần migration.
3. **Tốc độ cao:** Truy vấn theo `device_id` rất nhanh với Index.
4. **Motor (async driver):** Tích hợp hoàn hảo với FastAPI async.

### 4.2. Cấu Trúc Collection

**Collection:** `devices`

```json
{
  "_id": "ObjectId(...)",
  "device_id": "led_1",
  "name": "Đèn Phòng Khách",
  "type": "led",
  "status": true,
  "value": 0.0
}
```

| Field | Kiểu | Mô tả |
|---|---|---|
| `device_id` | String | ID duy nhất của thiết bị |
| `name` | String | Tên hiển thị |
| `type` | String | Loại thiết bị (led, sensor...) |
| `status` | Boolean | Trạng thái bật/tắt |
| `value` | Float | Giá trị cảm biến (nếu có) |

### 4.3. Kết Nối MongoDB trong FastAPI

```python
# file: app/core/database.py
from motor.motor_asyncio import AsyncIOMotorClient

class Database:
    client: AsyncIOMotorClient = None
    db = None

db = Database()

async def connect_to_mongo():
    db.client = AsyncIOMotorClient("mongodb://localhost:27017")
    db.db = db.client["smarthome_db"]
```

---

## 5. API Endpoints

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/` | Kiểm tra server |
| GET | `/device/{device_id}` | Lấy trạng thái thiết bị |
| POST | `/device/update` | Bật/tắt thiết bị + gửi MQTT |

**Ví dụ request POST /device/update:**
```json
{
  "device_id": "led_1",
  "status": true
}
```

---

## 6. Hướng Dẫn Cài Đặt MongoDB

> Xem file [HUONG_DAN_MONGODB.md](./HUONG_DAN_MONGODB.md) để biết cách cài đặt chi tiết.

---

## 7. Hướng Dẫn Chạy Dự Án

### Bước 1: Khởi động Backend
```bash
cd server_backend
venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Bước 2: Nạp Firmware lên ESP8266
- Mở PlatformIO → Upload `firmware_esp32/src/main.cpp`
- Theo dõi Serial Monitor (115200 baud)

### Bước 3: Chạy Flutter App
```bash
cd client_app
flutter run
```

### Bước 4: Test
- Bấm nút "Đèn Phòng Khách" → LED D2 sáng
- Bấm nút "Đèn Phòng Ngủ" → LED D5 sáng

---

## 8. Sơ Đồ Kết Nối Phần Cứng ESP8266

```
NodeMCU v2
┌──────────────┐
│  D2 (GPIO4)  │──[R 220Ω]──[LED1 +]──[LED1 -]──GND
│  D5 (GPIO14) │──[R 220Ω]──[LED2 +]──[LED2 -]──GND
│  GND         │──────────────────────────────── GND
└──────────────┘
```
