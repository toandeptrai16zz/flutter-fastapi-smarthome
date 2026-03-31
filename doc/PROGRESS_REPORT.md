# BÁO CÁO TIẾN ĐỘ: LINH ĐỘNG HÓA HỆ THỐNG IOT SMARTHOME

Dự án đã được nâng cấp toàn diện để đạt được tính **Di động (Mobility)** và **Ổn định (Stability)** trên mọi môi trường internet, bất kể là máy ảo Android hay điện thoại thật.

## 1. Các giải pháp kỹ thuật đã triển khai

### A. Backend & Connectivity (Kết nối vạn năng)
*   **Chuyển đổi sang Ngrok:** Sử dụng Ngrok thay cho Localtunnel để đạt tốc độ ổn định hơn và hỗ trợ WebSocket tốt hơn.
*   **Vượt rào bảo mật (Tunnel Bypass):** Thêm cơ chế tự động gửi các Header (`Bypass-Tunnel-Reminder`, `ngrok-skip-browser-warning`) để App không bao giờ bị kẹt tại trang cảnh báo của các dịch vụ Tunnel.
*   **Giả lập trình duyệt (User-Agent):** Cấu hình App gửi yêu cầu dưới danh nghĩa Chrome Browser để tránh bị các lớp Firewall chặn lọc traffic máy ảo.

### B. Mobile App Flutter (Linh hoạt & Thông minh)
*   **Menu cấu hình ẩn (Dynamic URL):** Nhấn giữ Logo tại màn hình Đăng nhập (3 giây) để đổi URL Backend ngay lập tức mà không cần sửa code/biên dịch lại.
*   **Bỏ qua xác thực SSL (SSL Bypass):** Triển khai `HttpOverrides` trong `main.dart` để giải quyết triệt để lỗi `HandshakeException` hoặc `Timeout` khi máy ảo không tin tưởng chứng chỉ của Tunnel.
*   **Tối ưu hóa Timeout:** Tăng thời gian chờ từ 5 giây lên 15 giây để duy trì kết nối ổn định ngay cả khi mạng 4G/WiFi yếu.

### C. ESP32 Firmware (WiFi Mobility)
*   **Tích hợp WiFiManager:** Loại bỏ hoàn toàn việc lưu "cứng" SSID/Password trong code.
*   **Cơ chế tự phát AP:** Khi đến môi trường mới (như trường học), ESP32 tự phát WiFi `SmartHome-Config` để bạn cấu hình mạng mới từ điện thoại chỉ trong 30 giây.

---

## 2. Hướng dẫn vận hành (Dành cho demo)

> [!IMPORTANT]
> **LUÔN LÀM THEO THỨ TỰ NÀY:**
> 1. Chạy Backend (Uvicorn) -> 2. Chạy Ngrok -> 3. Cập nhật Link vào App.

### Đối với Máy ảo Android
1.  Nếu máy ảo mất mạng: Thực hiện **Cold Boot Now** từ AVD Manager.
2.  Mở trình duyệt trong máy ảo, truy cập link Ngrok 1 lần (để chắc chắn máy ảo đã thông mạng).
3.  Dán link Ngrok vào App (Menu ẩn) và sử dụng.

### Câu lệnh chạy FE
1. flutter emulators --launch Medium_Phone_API_36.0
2. flutter run

### Câu lệnh chạy BE
1.  .\venv\Scripts\activate   (Môi trường ảo)
2. ./ngrok http 8000
3. Dán Link puclic của ngrok trả vào app
4. chạy backend: python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload 

### Đối với Điện thoại thật
1.  Đảm bảo điện thoại có mạng (WiFi hoặc 4G).
2.  Dán link Ngrok tương tự như trên máy ảo.
3.  Máy thật sẽ chạy cực kỳ mượt mà vì nó có phần cứng mạng mạnh hơn máy ảo.

---

## 3. Trạng thái hiện tại
- **Backend:** [Đang chạy] `optical-yevette-compactly.ngrok-free.dev`
- **Dữ liệu realtime:** [Hoạt động] Sensor DHT11 bắn dữ liệu liên tục 34.3°C, 95%.
- **Độ ổn định:** [Cao] Đã xử lý lỗi Timeout và SSL.

---
**Chúc bạn có buổi báo cáo thành công!** 🚀
