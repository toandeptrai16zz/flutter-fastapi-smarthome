# 🏠 ĐỒ ÁN TỐT NGHIỆP: HỆ THỐNG NHÀ THÔNG MINH AIOT (SMARTHOME AI 2026)

**Sinh viên thực hiện:** Hà Quang Chương  
**Lớp:** D17DT&KTMT1 - Khóa D17  
**Ngành:** Công nghệ Kỹ thuật Điện tử Viễn thông  
**Trường:** Đại học Điện lực (EPU)  
**Ngày báo cáo:** 04/04/2026  

---

## 📑 MỤC LỤC
1. [Giới thiệu dự án](#1-giới-thiệu-dự-án)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Phát triển phần cứng (Hardware)](#3-phát-triển-phần-cứng)
4. [Xây dựng Backend Server (FastAPI)](#4-xây-dựng-backend-server)
5. [Ứng dụng Mobile (Flutter App)](#5-ứng-dụng-mobile)
6. [Trợ lý ảo AI & An ninh thông minh](#6-trợ-lý-ảo-ai--an-ninh-thông-minh)
7. [Cơ sở dữ liệu & Thời gian thực (Realtime)](#7-cơ-sở-dữ-liệu--thời-gian-thực)
8. [Hướng dẫn vận hành](#8-hướng-dẫn-vận-hành)
9. [Kết quả & Đánh giá](#9-kết-quả--đánh-giá)
10. [Kết luận & Hướng phát triển](#10-kết-luận--hướng-phát-triển)

---

## 1. Giới thiệu dự án
Dự án "SmartHome AI 2026" được xây dựng nhằm giải quyết nhu cầu về một hệ thống quản lý nhà ở thông minh, linh hoạt và có khả năng tương tác tự nhiên với người dùng thông qua Trí tuệ nhân tạo (AI). Khác với các hệ thống truyền thống chỉ điều khiển bật/tắt đơn thuần, dự án này tích hợp mô hình ngôn ngữ lớn (LLM) để hiểu và thực thi các mệnh lệnh phức tạp, đồng thời tự động hóa dựa trên ngữ cảnh và cảm biến.

**Mục tiêu cốt lõi:**
- Điều khiển thiết bị từ xa không giới hạn khoảng cách (qua Ngrok/Cloud).
- Giao tiếp với nhà bằng giọng nói (AI Gen Z Style).
- Tự động hóa lịch trình và cảnh báo an ninh thông minh.
- Đồng bộ dữ liệu tức thời (Realtime sync) giữa tất cả các client.

---

## 2. Kiến trúc hệ thống
Hệ thống được thiết kế theo mô hình 3 lớp (3-tier Architecture) với các giao tiếp hiện đại nhất hiện nay:

- **Tầng Giao diện (Presentation Layer):** Flutter (Android/iOS) cho phép điều khiển trực quan và ra lệnh giọng nói.
- **Tầng Xử lý (Logic Layer):** FastAPI (Python) quản lý luồng dữ liệu, điều hướng lệnh AI và giám sát lịch trình.
- **Tầng Thiết bị (Physical Layer):** ESP8266 (NodeMCU) và ESP32-CAM trực tiếp tương tác với Relay, cảm biến PIR, DHT11.

---

## 3. Phát triển phần cứng
### 3.1. Danh sách linh kiện
| STT | Linh kiện | Chức năng |
|---|---|---|
| 1 | ESP8266 NodeMCU v2 | Chip điều khiển chính (Cảm biến & Relay) |
| 2 | ESP32-CAM | Camera giám sát + Flash LED |
| 3 | DHT11 | Cảm biến Nhiệt độ & Độ ẩm |
| 4 | PIR (HC-SR501) | Cảm biến chuyển động hồng ngoại |
| 5 | Module Relay 5V | Đóng ngắt thiết bị 220V |

### 3.2. Sơ đồ đấu nối (Wiring Diagram)
**Bảng gán chân thực tế (An toàn tránh treo Boot):**
- **DHT11:** D1 (GPIO 5).
- **PIR:** D2 (GPIO 4).
- **Relay 1:** D7 (GPIO 13).
- **Relay 2:** D6 (GPIO 12).
- **Nút bấm 1:** D3 (GPIO 0).
- **Nút bấm 2:** D4 (GPIO 2).

---

## 4. Xây dựng Backend Server
Backend được xây dựng trên nền tảng **FastAPI** mạnh mẽ, tận dụng cơ chế `async/await` để xử lý hàng ngàn kết nối đồng thời.

- **MQTT Bridge:** Chuyển tiếp lệnh từ Web/Mobile tới thiết bị IoT trong <50ms.
- **Scheduler Engine:** Hệ thống tự động kiểm tra và thực thi lịch trình mỗi phút.
- **WebSocket Manager:** Duy trì kết nối "Always-on" với App để cập nhật trạng thái ngay lập tức.
- **JWT Authentication:** Bảo mật thông tin người dùng.

---

## 5. Ứng dụng Mobile (Flutter App)
Giao diện App thiết kế theo phong cách **Glassmorphism**, tập trung vào trải nghiệm mượt mà.

- **Dashboard:** Hiển thị nhiệt độ, độ ẩm và lưới thiết bị động.
- **AI Chat:** Giao diện trò chuyện/ra lệnh giọng nói.
- **Camera Room:** Theo dõi trực tiếp video từ ESP32-CAM.

---

## 6. Trợ lý ảo AI & An ninh thông minh
### 6.1. Trợ lý AI Llama-3.3 (Gen Z Mode)
Hiểu được các yêu cầu tự nhiên: *"Nóng quá đi mất"* -> Bật quạt; *"Đi ngủ thôi"* -> Tắt toàn bộ đèn.

### 6.2. AI An Ninh (Security Engine)
- **Ban đêm:** Bật báo động và push notification nếu phát hiện chuyển động.
- **Ban ngày:** Chỉ thông báo nhẹ nhàng.

---

## 7. Cơ sở dữ liệu & Thời gian thực
### 7.1. MongoDB (NoSQL)
Lưu trữ trạng thái thiết bị và lịch sử cảm biến linh hoạt, không cần schema cứng.
### 7.2. WebSocket Realtime
Đồng bộ hóa tức thời mọi hành động giữa App, Backend và Thiết bị IoT.

---

## 8. Kết quả đạt được
Hệ thống đạt độ trễ cực thấp (<100ms), AI phản hồi hài hước theo cá tính Gen Z, và khả năng mở rộng thiết bị động cực kỳ linh hoạt (Dynamic Mapping).

---
*(Hết báo báo)*
