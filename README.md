# 🏠 Nhà Thông Minh AIoT SmartHome

## Thông tin đồ án

- **Sinh viên thực hiện:** Hà Quang Chương
- **Lớp:** D17DT&KTMT1 - Khóa D17
- **Ngành:** Công nghệ Kỹ thuật Điện tử Viễn thông
- **Trường:** Đại học Điện lực (EPU)
- **Thành phần dự án:** Hệ thống Nhà thông minh AIoT hoàn chỉnh (Mobile App + Backend Server + Firmware ESP32 + Trợ lý AI giọng nói)

---

## 🚀 Báo Cáo Tiến Độ

**Cập nhật lần cuối: 02/04/2026**

Hệ thống AIoT SmartHome đã được phát triển hoàn chỉnh với kiến trúc **3 lớp (3-Tier Architecture)**: Ứng dụng di động Flutter, Backend FastAPI (Python), và Firmware ESP32 (C++). Tích hợp **Trợ lý AI giọng nói** sử dụng công nghệ LPU siêu tốc của Groq (Model Llama-3.3-70B). Giao tiếp thời gian thực qua **WebSocket** và **MQTT**.

---

## 🏗️ Kiến Trúc Hệ Thống

```
┌──────────────┐     WebSocket      ┌──────────────────┐       MQTT        ┌──────────────┐
│  Flutter App  │◄──────────────────►│  FastAPI Backend  │◄────────────────►│    ESP32      │
│  (Mobile UI)  │     HTTP REST      │  (Python Server)  │                  │  (Phần cứng)  │
└──────┬───────┘                    └────────┬─────────┘                  └──────┬───────┘
       │                                     │                                   │
       │  Speech-to-Text                     │  Groq AI (Llama-3)                │  DHT11 Sensor
       │  Text-to-Speech                     │  MongoDB                          │  LED / Relay
       │  Locale vi_VN                       │  Scheduler                        │  WiFiManager
       └─────────────────────────────────────┴───────────────────────────────────┘
```

---

## ✅ Các Tính Năng Đã Hoàn Thiện

### 🤖 Trợ Lý AI Giọng Nói (MỚI)
- [x] **Nhận diện giọng nói tiếng Việt:** Tích hợp `speech_to_text` với quét locale tự động, đảm bảo nhận diện chính xác trên mọi thiết bị Android/iOS.
- [x] **Bộ não AI siêu tốc:** Sử dụng **Groq Cloud** (chip LPU) với model **Llama-3.3-70B-Versatile**, độ trễ phản hồi gần bằng 0.
- [x] **Điều khiển bằng ngôn ngữ tự nhiên:** Nói *"Nhà ơi bật đèn phòng khách"* → AI phân tích ý định → Gửi lệnh MQTT → Thiết bị bật → App cập nhật UI ngay lập tức.
- [x] **Phản hồi bằng giọng nói (TTS):** AI trả lời bằng tiếng Việt tự nhiên, phát qua loa điện thoại.
- [x] **Tính cách AI:** Giao tiếp vui vẻ, thân thiện kiểu Gen Z Việt Nam 🇻🇳
- [x] **Nhập lệnh bằng bàn phím:** Tính năng dự phòng cho môi trường máy ảo (không có micro).

### 🔐 Xác Thực & Quản Lý Người Dùng
- [x] **Hệ thống đăng ký & đăng nhập:** Xác thực JWT Token qua API Backend.
- [x] **Màn hình Đăng nhập:** Giao diện hiện đại, hỗ trợ chế độ Dark/Light.
- [x] **Quên mật khẩu:** Thiết kế theo phong cách Glassmorphism (kính mờ) với hiệu ứng phát sáng.
- [x] **Đăng nhập mạng xã hội:** Tích hợp giao diện đăng nhập với Google.

### 📱 Bảng Điều Khiển Chính (Dashboard)
- [x] **Thanh điều hướng dưới cùng:** 4 tab: Trang chủ, Lịch trình, Thống kê, Cài đặt.
- [x] **Dữ liệu cảm biến thời gian thực:** Nhiệt độ & Độ ẩm từ DHT11 cập nhật liên tục qua WebSocket.
- [x] **Lưới thiết bị:** Trạng thái Bật/Tắt đồng bộ thời gian thực giữa App ↔ Server ↔ Phần cứng.
- [x] **Tương tác:** Chạm để bật/tắt, nhấn giữ để mở menu tùy chọn (Chia sẻ, Cài đặt, Xóa).
- [x] **Tab Thống kê:** Biểu đồ cột trực quan hóa mức tiêu thụ điện hàng tuần.
- [x] **Tab Cài đặt:** Chuyển đổi ngôn ngữ (VI/EN), Dark/Light Mode, thông báo đẩy.

### ⏰ Tự Động Hóa & Lịch Trình
- [x] **Hẹn giờ bật/tắt thiết bị:** Tạo lịch trình với bộ chọn thời gian kiểu iOS (Cupertino Picker).
- [x] **Lặp lại theo ngày:** Chọn các ngày trong tuần để lặp lại tác vụ tự động.
- [x] **Đồng bộ UI realtime:** Khi lịch trình kích hoạt, App tự động cập nhật trạng thái công tắc qua WebSocket.
- [x] **Xóa bằng cử chỉ:** Vuốt để xóa lịch trình (Dismissible).

### 🌐 Backend Server (FastAPI + Python)
- [x] **RESTful API:** Endpoints đầy đủ cho devices, sensors, schedules, AI chat.
- [x] **WebSocket Server:** Kết nối realtime 2 chiều với Flutter App (ping/pong keep-alive).
- [x] **MongoDB:** Cơ sở dữ liệu NoSQL lưu trữ thiết bị, cảm biến, lịch trình, logs.
- [x] **MQTT Client:** Giao tiếp với ESP32 qua broker HiveMQ (Public).
- [x] **Scheduler Engine:** Vòng lặp kiểm tra lịch trình mỗi phút, tự động kích hoạt thiết bị.
- [x] **AI Auto Cooling:** Khi nhiệt độ ≥ 31°C, AI tự động bật quạt và thông báo cho người dùng.

### 🔌 Firmware ESP32 (C++ / PlatformIO)
- [x] **WiFiManager:** Cấu hình WiFi qua giao diện captive portal (không cần hardcode SSID).
- [x] **MQTT Subscribe:** Nhận lệnh bật/tắt LED từ Backend qua topic `smarthome/devices/+/control`.
- [x] **DHT11 Sensor:** Đọc nhiệt độ & độ ẩm mỗi 5 giây, publish lên MQTT.
- [x] **ArduinoOTA:** Hỗ trợ nạp firmware không dây qua WiFi (Over-The-Air Update).

### 🎨 Giao Diện & Trải Nghiệm
- [x] **Dark Mode / Light Mode:** Toàn bộ UI tự động thay đổi theo cài đặt người dùng.
- [x] **Đa ngôn ngữ:** Hỗ trợ Tiếng Việt và English, chuyển đổi tức thì.
- [x] **Chia sẻ thiết bị:** Quản lý thành viên gia đình với phân quyền (Admin/Control/View).
- [x] **Thiết kế Glassmorphism:** Hiệu ứng kính mờ cao cấp trên các màn hình xác thực.

---

## 🛠 Công Nghệ Sử Dụng

| Thành phần | Công nghệ | Phiên bản / Ghi chú |
|------------|-----------|---------------------|
| **Mobile App** | Flutter (Dart) | Cross-platform Android/iOS |
| **Backend** | FastAPI (Python) | Async/Await, Uvicorn |
| **AI Engine** | Groq Cloud (LPU) | Model: Llama-3.3-70B-Versatile |
| **Database** | MongoDB | NoSQL, Motor (Async Driver) |
| **Realtime** | WebSocket | 2-way, ping/pong keep-alive |
| **IoT Protocol** | MQTT | Broker: HiveMQ (Public) |
| **Firmware** | C++ / PlatformIO | ESP8266 + DHT11 + ArduinoOTA |
| **Speech-to-Text** | Google Speech Services | Locale: vi_VN (auto-detect) |
| **Text-to-Speech** | Flutter TTS | Giọng Tiếng Việt |
| **Auth** | JWT Token | bcrypt password hashing |

---

## 📂 Cấu Trúc Dự Án

```
IoT_SmartHome_Project/
│
├── client_app/                          # 📱 Ứng dụng Flutter
│   └── lib/
│       ├── main.dart                    # Điểm khởi đầu ứng dụng
│       ├── theme/
│       │   └── app_theme.dart           # Quản lý Dark/Light Mode
│       ├── screens/
│       │   ├── auth/
│       │   │   ├── login_screen.dart    # Đăng nhập
│       │   │   └── forgot_password_screen.dart
│       │   ├── home/
│       │   │   └── dashboard_screen.dart # Dashboard + AI Voice
│       │   ├── automation/
│       │   │   └── schedule_screen.dart  # Quản lý lịch trình
│       │   └── device/
│       │       └── share_device_screen.dart
│       ├── services/
│       │   ├── api_service.dart          # HTTP Client (REST API)
│       │   └── websocket_service.dart    # WebSocket Realtime
│       └── utils/
│           └── constants.dart            # Base URL, WS URL
│
├── server_backend/                      # 🐍 Backend FastAPI
│   ├── app/
│   │   ├── main.py                      # Server chính (API + WS + AI + Scheduler)
│   │   ├── core/
│   │   │   ├── config.py                # Cấu hình (env variables)
│   │   │   └── database.py              # Kết nối MongoDB
│   │   ├── services/
│   │   │   ├── mqtt_service.py          # MQTT Client
│   │   │   └── websocket_manager.py     # WS Connection Manager
│   │   ├── models/
│   │   │   └── schedule.py              # Pydantic Models
│   │   └── api/
│   │       └── auth.py                  # JWT Authentication
│   ├── .env                             # Biến môi trường (API Keys) ⚠️ Không push lên Git
│   └── requirements.txt                 # Dependencies Python
│
├── firmware_esp32/                      # 🔌 Firmware ESP32
│   ├── src/
│   │   └── main.cpp                     # Code C++ (WiFi + MQTT + DHT11 + OTA)
│   └── platformio.ini                   # Cấu hình PlatformIO
│
├── doc/                                 # 📄 Tài liệu dự án
│   ├── BAO_CAO.md                       # Báo cáo tổng quan
│   ├── Bao_Cao_Tich_Hop_AI.md           # Báo cáo tích hợp AI Groq
│   └── Ke_Hoach_Phat_Trien_He_Thong_Thiet_Bi_Dong.md  # Kế hoạch phát triển
│
└── README.md                            # 📋 File này
```

---

## 🚀 Hướng Dẫn Chạy Dự Án

### 1. Backend Server

```bash
cd server_backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
# Tạo file .env với GROQ_API_KEY và MONGODB_URL
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Mobile App (Flutter)

```bash
cd client_app
flutter pub get
# Cập nhật URL Backend trong lib/utils/constants.dart
flutter run
```

### 3. Firmware ESP32

```bash
cd firmware_esp32
# Mở bằng PlatformIO (VS Code Extension)
# Chọn Board: ESP8266 (NodeMCU)
# Upload lần đầu qua USB, sau đó dùng OTA qua WiFi
```

---

## 📝 Kế Hoạch Phát Triển Tiếp Theo

- **Hệ thống Device Registry Động:** Thêm/Sửa/Xóa thiết bị từ App mà không cần sửa code. *(Xem chi tiết: `doc/Ke_Hoach_Phat_Trien_He_Thong_Thiet_Bi_Dong.md`)*
- **Nút bấm vật lý trên ESP32:** Điều khiển ngược từ phần cứng lên App.
- **Hỗ trợ nhiều loại thiết bị:** Điều hòa, rèm cửa, hệ thống tưới cây...
- **Dashboard Analytics thực:** Biểu đồ tiêu thụ điện từ dữ liệu thật.

---

> 💡 *"Dự án đang trong quá trình phát triển liên tục. Xem thêm tài liệu chi tiết trong thư mục `doc/`."*
