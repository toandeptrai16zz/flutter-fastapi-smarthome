# 🏠 Nhà Thông Minh AIoT SmartHome

## Thông tin đồ án

- **Sinh viên thực hiện:** Hà Quang Chương
- **Lớp:** D17DT&KTMT1 - Khóa D17
- **Ngành:** Công nghệ Kỹ thuật Điện tử Viễn thông
- **Trường:** Đại học Điện lực (EPU)
- **Thành phần dự án:** Hệ thống Nhà thông minh AIoT hoàn chỉnh (Mobile App + Backend Server + Firmware ESP32 + Trợ lý AI giọng nói)

---

## 🚀 Báo Cáo Tiến Độ & Cập Nhật Mới (AI 2.0)

**Cập nhật lần cuối: 02/04/2026**

Hệ thống đã chính thức nâng cấp lên phiên bản **AI 2.0** với các tính năng đột phá:
- **🧠 Trợ lý AI Gen Z (Llama-3.3-70b)**: Phản hồi cực nhanh, hiểu tiếng lóng, sai ngữ pháp, và cá tính linh hoạt (Gen Z Mode).
- **⏱️ Hệ thống Hẹn giờ 2.0**: Tự động nhận diện chân Pin (GPIO) và logic Active Low cho từng thiết bị.
- **📍 Điều khiển Room-Aware**: AI tự phân biệt "Đèn phòng ngủ" và "Đèn phòng khách" dựa trên vị trí thực tế trong DB.
- **📡 WebSocket Real-time 2.0**: Đồng bộ hóa nhãn Pin (D1, D2...) và trạng thái ngay lập tức khi mở App.

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

### 🤖 Trợ Lý AI Giọng Nói (Gen Z Edition)
- [x] **Nhận diện giọng nói tiếng Việt:** Tích hợp `speech_to_text` với quét locale tự động.
- [x] **Bộ não AI siêu tốc:** Sử dụng **Groq Cloud** (chip LPU) với model **Llama-3.3-70B-Versatile**.
- [x] **Thông minh đột xuất:** Hiểu tiếng Anh bồi, tiếng lóng, sai ngữ pháp (vd: 'light bed on' -> Bật đèn ngủ).
- [x] **Tính cách Gen Z:** Giao tiếp hài hước, mặn mòi kiểu Gen Z Việt Nam (vd: 'oke nha', 'mlem', 'đỉnh nóc').
- [x] **Fuzzy Matching:** Tự động ánh xạ tên thiết bị và phòng để ra lệnh chính xác 100%.

### 🔐 Xác Thực & Quản Lý Người Dùng
- [x] **Hệ thống đăng ký & đăng nhập:** Xác thực JWT Token qua API Backend.
- [x] **Màn hình Đăng nhập:** Giao diện hiện đại, hỗ trợ chế độ Dark/Light.
- [x] **Quên mật khẩu:** Thiết kế theo phong cách Glassmorphism (kính mờ).
- [x] **Đăng nhập mạng xã hội:** Tích hợp giao diện đăng nhập với Google.

### 📱 Bảng Điều Khiển Chính (Dashboard)
- [x] **Dữ liệu cảm biến thời gian thực:** Nhiệt độ & Độ ẩm từ DHT11 cập nhật liên tục qua WebSocket.
- [x] **Lưới thiết bị:** Trạng thái Bật/Tắt đồng bộ thời gian thực giữa App ↔ Server ↔ Phần cứng.
- [x] **Dynamic GPIO Mapping:** Gán chân Pin tùy ý trên App mà không cần nạp lại Firmware ESP32.
- [x] **Nhãn Pin thông minh:** Hiển thị nhãn D1, D2... ngay trên card thiết bị để dễ đối chiếu phần cứng.

### ⏰ Tự Động Hóa & Lịch Trình (Smart Scheduling)
- [x] **Hẹn giờ thông minh:** Tự động áp dụng chân Pin và logic Active Low (gạt lên tắt/xuống bật) cho từng lịch trình.
- [x] **Đồng bộ UI realtime:** Khi lịch trình kích hoạt, App tự động cập nhật trạng thái qua WebSocket.
- [x] **Hiển thị chân Pin:** Màn hình lịch trình hiện rõ thiết bị nào đang được hẹn giờ ở chân Pin nào.

### 🌐 Backend Server (FastAPI + Python)
- [x] **RESTful API:** Endpoints đầy đủ cho devices, sensors, schedules, AI chat.
- [x] **WebSocket Server:** Kết nối realtime 2 chiều (ping/pong keep-alive).
- [x] **Scheduler Engine:** Vòng lặp kiểm tra lịch trình mỗi phút, hỗ trợ JSON control cho ESP32.
- [x] **AI Auto Cooling:** Khi nhiệt độ ≥ 31°C, AI tự động bật quạt và thông báo.

### 🔌 Firmware ESP32 (C++ / PlatformIO)
- [x] **WiFiManager:** Cấu hình WiFi qua giao diện captive portal.
- [x] **MQTT Subscribe:** Nhận lệnh JSON `{ "pin": ..., "action": ... }` linh hoạt.
- [x] **DHT11 Sensor:** Đọc nhiệt độ & độ ẩm mỗi 5 giây, publish lên MQTT.

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
| **Firmware** | C++ / PlatformIO | ESP32 + DHT11 + ArduinoOTA |

---

## 📂 Cấu Trúc Dự Án

```
IoT_SmartHome_Project/
├── client_app/                          #  Ứng dụng Flutter
├── server_backend/                      #  Backend FastAPI
├── firmware_esp32/                      #  Firmware ESP32
├── doc/                                 #  Tài liệu dự án
└── README.md                            #  File này
```

---

## 🚀 Hướng Dẫn Chạy Dự Án

### 1. Backend Server
```bash
cd server_backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Mobile App (Flutter)
```bash
cd client_app
flutter run
```

---

## 📝 Kế Hoạch Phát Triển Tiếp Theo
- **Nút bấm vật lý trên ESP32:** Điều khiển ngược từ phần cứng lên App.
- **Hỗ trợ camera giám sát:** Tích hợp luồng stream video vào App.
- **Hệ thống cảnh báo an ninh:** Sử dụng cảm biến hồng ngoại và thông báo đẩy.

---

> 💡 **"Dự án đang được phát triển liên tục. Vui lòng đọc tài liệu chi tiết trong thư mục `doc/`."**
