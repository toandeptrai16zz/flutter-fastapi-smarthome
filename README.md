# 🏠 Nhà Thông Minh AIoT SmartHome

## Thông tin đồ án

- **Sinh viên thực hiện:** Hà Quang Chương
- **Lớp:** D17DT&KTMT1 - Khóa D17
- **Ngành:** Công nghệ Kỹ thuật Điện tử Viễn thông
- **Trường:** Đại học Điện lực (EPU)
- **Thành phần dự án:** Hệ thống Nhà thông minh AIoT hoàn chỉnh (Mobile App + Backend Server + Firmware ESP32 + Trợ lý AI giọng nói)

---

##  Báo Cáo Tiến Độ & Cập Nhật Mới (AI 2.0)

**Cập nhật lần cuối: 03/04/2026**

Hệ thống đã chính thức nâng cấp lên phiên bản **AI 2.0** với các tính năng đột phá:
- ** Trợ lý AI Gen Z (Llama-3.3-70b)**: Phản hồi cực nhanh, hiểu tiếng lóng, sai ngữ pháp, và cá tính linh hoạt (Gen Z Mode).
- ** Hệ thống Hẹn giờ 2.0**: Tự động nhận diện chân Pin (GPIO) và logic Active Low cho từng thiết bị. Danh sách thiết bị trong Lịch trình luôn đồng bộ realtime với trang chủ.
- ** Điều khiển Room-Aware**: AI tự phân biệt "Đèn phòng ngủ" và "Đèn phòng khách" dựa trên vị trí thực tế trong DB.
- ** Anti-Hallucination AI**: Trợ lý AI có chế độ kỷ luật thép, chống bịa đặt thiết bị (không đòi bật quạt nếu nhà không có quạt).
- ** Đấu nối Cứng & Linh Hoạt**: Tương thích tốt các cảm biến thông dụng (PIR, DHT11) và Camera giám sát (ESP-CAM ESP32 stream MJPEG).
- ** WebSocket Real-time 2.0**: Đồng bộ hóa nhãn Pin (D1, D2...) và trạng thái ngay lập tức khi mở App.
- ** Nút bấm vật lý 2 chiều**: Nhấn nút cứng trên mạch → App cập nhật trạng thái realtime qua MQTT → WebSocket.
- ** AI An Ninh thông minh**: Cảm biến PIR chỉ cảnh báo khi thực sự phát hiện chuyển động (cooldown 120s), không spam thông báo.

---

## 🏗️ Kiến Trúc Hệ Thống

```
┌──────────────┐     WebSocket      ┌──────────────────┐       MQTT        ┌──────────────┐
│  Flutter App  │◄──────────────────►│  FastAPI Backend  │◄────────────────►│    ESP32      │
│  (Mobile UI)  │     HTTP REST      │  (Python Server)  │                  │  (Phần cứng)  │
└──────┬───────┘                    └────────┬─────────┘                  └──────┬───────┘
       │                                     │                                   │
       │  Speech-to-Text                     │  Groq AI (Llama-3)                │  DHT11 Sensor
       │  Text-to-Speech                     │  MongoDB                          │  PIR Sensor
       │  Locale vi_VN                       │  Scheduler                        │  Relay + Nút bấm
       └─────────────────────────────────────┴───────────────────────────────────┘
```

---

## ✅ Các Tính Năng Đã Hoàn Thiện

###  Trợ Lý AI Giọng Nói (Gen Z Edition)
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
- [x] **Nút bấm vật lý đồng bộ 2 chiều:** Nhấn nút trên mạch ESP → App cập nhật trạng thái realtime qua MQTT + WebSocket.

###  Tự Động Hóa & Lịch Trình (Smart Scheduling)
- [x] **Hẹn giờ thông minh:** Tự động áp dụng chân Pin và logic Active Low (gạt lên tắt/xuống bật) cho từng lịch trình.
- [x] **Đồng bộ UI realtime:** Khi lịch trình kích hoạt, App tự động cập nhật trạng thái qua WebSocket.
- [x] **Hiển thị chân Pin:** Màn hình lịch trình hiện rõ thiết bị nào đang được hẹn giờ ở chân Pin nào.
- [x] **Đồng bộ thiết bị mới nhất:** Danh sách thiết bị trong form tạo lịch trình luôn lấy từ DB mới nhất, đồng bộ khớp với trang chủ.

###  AI An Ninh & Cảm Biến Chuyển Động (PIR)
- [x] **Phát hiện chuyển động:** Cảm biến PIR gửi cảnh báo realtime qua MQTT topic riêng (`smarthome/sensors/pir/data`).
- [x] **AI An Ninh tự động:** Khi phát hiện chuyển động, AI đánh giá mức độ nguy hiểm theo giờ (ban đêm = báo động, ban ngày = thông báo nhẹ).
- [x] **Chống spam thông báo:** Cooldown 120 giây, không spam liên tục khi PIR liên tục trigger.
- [x] **Push Notification:** Đẩy thông báo khẩn cấp lên điện thoại qua Awesome Notifications.

###  Backend Server (FastAPI + Python)
- [x] **RESTful API:** Endpoints đầy đủ cho devices, sensors, schedules, AI chat.
- [x] **WebSocket Server:** Kết nối realtime 2 chiều (ping/pong keep-alive).
- [x] **Scheduler Engine:** Vòng lặp kiểm tra lịch trình mỗi phút, hỗ trợ JSON control cho ESP32.
- [x] **AI Auto Cooling:** Khi nhiệt độ ≥ 31°C, AI tự động bật quạt và thông báo (cooldown 10 phút).
- [x] **Đồng bộ nút bấm vật lý:** Backend map `relay1 → GPIO 13 (D7)`, `relay2 → GPIO 12 (D6)` để tìm thiết bị trong DB và broadcast `device_update` qua WebSocket.

###  Cấu Hình Đấu Nối Cứng ESP32 NodeMCU

> ⚠️ **Lưu ý quan trọng:** Chân D3 (GPIO 0) và D4 (GPIO 2) là chân Bootstrap. **KHÔNG được nối Relay/LED vào D3/D4** vì sẽ gây treo hệ thống khi khởi động. Chỉ nên dùng D3/D4 cho nút bấm (INPUT_PULLUP) vì nút nhả hở mạch lúc boot.

| Chân | GPIO | Chức năng | Ghi chú |
|------|------|-----------|---------|
| `D1` | GPIO 5 | Cảm biến DHT11 (Nhiệt độ/Độ ẩm) | Hardcoded, không dùng cho thiết bị khác |
| `D2` | GPIO 4 | Cảm biến PIR (Chuyển động) | Hardcoded, INPUT only |
| `D3` | GPIO 0 | Nút bấm vật lý 1 | Bootstrap pin - Chỉ dùng INPUT_PULLUP |
| `D4` | GPIO 2 | Nút bấm vật lý 2 | Bootstrap pin - Chỉ dùng INPUT_PULLUP |
| `D5` | GPIO 14 | ~~Relay 1~~ → **Trống (Có thể gán từ App)** | Chân sạch, an toàn |
| `D6` | GPIO 12 | **Relay 2** | Active High qua Transistor 2N2222 |
| `D7` | GPIO 13 | **Relay 1** | Active High qua Transistor 2N2222 |
| `D8` | GPIO 15 | Trống (Có thể gán từ App) | Cẩn thận: Pull-down lúc boot |

### 🎛 Firmware ESP32 (C++ / PlatformIO)
- [x] **WiFiManager:** Cấu hình WiFi qua giao diện captive portal.
- [x] **MQTT Subscribe:** Nhận lệnh JSON `{ "pin": ..., "action": ... }` linh hoạt.
- [x] **DHT11 Sensor & PIR:** Đọc cảnh báo phát hiện chuyển động theo thời gian thực và push sensor data lên HiveMQ.
- [x] **Camera MJPEG ESP32-CAM:** Stream video hoạt động trơn tru dựa trên thư viện flutter_mjpeg đa nền tảng kết hợp điều khiển đèn Flash.
- [x] **Nút bấm vật lý:** 2 nút (D3, D4) điều khiển Relay 1 (D7) và Relay 2 (D6), đồng thời publish trạng thái lên MQTT để App biết.
- [x] **ArduinoOTA:** Hỗ trợ nạp firmware không dây qua WiFi.

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
| **Firmware** | C++ / PlatformIO | ESP8266 NodeMCU + DHT11 + PIR + ArduinoOTA |
| **Camera** | ESP32-CAM | MJPEG Stream + Flash LED control |
| **Notification** | Awesome Notifications | Push notification trên Android |

---

## 📂 Cấu Trúc Dự Án

```
IoT_SmartHome_Project/
├── client_app/                          #  Ứng dụng Flutter
├── server_backend/                      #  Backend FastAPI
├── firmware_esp32/                      #  Firmware ESP8266 NodeMCU (Cảm biến + Relay)
├── firmware_esp32_cam/                  #  Firmware ESP32-CAM (Camera giám sát)
├── doc/                                 #  Tài liệu dự án
└── README.md                            #  File này
```

---

##  Hướng Dẫn Chạy Dự Án

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

### 3. Firmware ESP8266 (PlatformIO)
```bash
cd firmware_esp32
pio run --target upload
```

### 4. Firmware ESP32-CAM (PlatformIO)
```bash
cd firmware_esp32_cam
pio run --target upload
```

---

##  Các Bug Đã Sửa (Changelog)

### 03/04/2026
- **Fix PIR spam thông báo:** Tách topic PIR (`smarthome/sensors/pir/data`) khỏi topic DHT. Chỉ kích AI Security khi nhận event PIR riêng, cooldown 120s thay vì 15s.
- **Fix nút bấm vật lý không đồng bộ App:** Sửa relay_map trong backend từ label sai (D1-D4) sang GPIO number đúng (relay1→GPIO13, relay2→GPIO12).
- **Fix schedule không hiện thiết bị mới:** Dropdown lịch trình giờ luôn tải fresh danh sách thiết bị từ DB mỗi khi mở dialog.
- **Fix AI Auto Cooling spam:** Cooldown chuyển từ 10s (test mode) sang 600s (production).

### 02/04/2026
- **Fix Bootstrap Pin:** Dời Relay từ D3/D4 sang D5/D6 (sau đó D7/D6) để tránh treo boot.
- **Fix GPIO 0 bug:** Sửa lỗi Python `if gpio_pin` đánh giá sai khi `gpio_pin=0`.
- **Fix PIR stuck HIGH:** Sửa lỗi cấu hình sai mode OUTPUT cho chân cảm biến PIR.

---

## 📝 Kế Hoạch Phát Triển Tiếp Theo
- **Tích hợp cảm biến mở cửa (Door Sensor):** Báo động tự động khi cửa bị mở.
- **Micro-animations & GenZ UI:** Nâng cấp thêm các hiệu ứng vuốt/chạm xịn xò cho App.
- **Web Dashboard:** Triển khai thêm một giao diện Web Admin bằng React/Vue để quản lý thiết bị trên PC.

---

> 💡 **"Dự án đang được phát triển liên tục. Vui lòng đọc tài liệu chi tiết trong thư mục `doc/`."**
