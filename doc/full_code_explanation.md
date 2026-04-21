# GIẢI THÍCH CHI TIẾT CƠ CHẾ HOẠT ĐỘNG HỆ THỐNG SMARTHOME AIoT

Tài liệu này dùng để chuẩn bị cho phần trả lời vấn đáp với giảng viên. Nội dung giải thích chi tiết logic từng khối code chính trong hệ thống.

---

## 1. BACKEND CORE (Hệ điều hành của Server)

### main.py - File chạy chính
*   **Lifespan Hook (`asynccontextmanager`)**: Quản lý vòng đời ứng dụng. Khi bật Server, nó sẽ tự động gọi hàm kết nối Database, khởi động MQTT và chạy vòng lặp Hẹn giờ. Khi tắt Server, nó sẽ hủy các Task để tránh rò rỉ bộ nhớ.
*   **CORS Middleware**: Cổng an ninh. Cho phép App Flutter từ bên ngoài có thể gửi yêu cầu (Request) tới Server mà không bị trình duyệt chặn.
*   **WebSocket Endpoint (`/ws`)**: Cổng WebSocket. Đây là nơi duy trì kết nối 2 chiều liên tục. Khi có điện thoại kết nối vào, Server sẽ ngay lập tức gửi toàn bộ danh sách thiết bị và nhiệt độ hiện tại xuống để App hiển thị tức thì.

### config.py - Cấu hình hệ thống
*   **Settings Class**: Tự động nạp các thông tin từ file `.env` (như API Key, Mật khẩu DB). Điều này giúp bảo mật, không để lộ chìa khóa quan trọng trong code.
*   **ESP32_PIN_MAP**: Từ điển ánh xạ. Giúp code hiểu rằng nhãn "D1" tương ứng với số chân vật lý "GPIO 5". Đây là cầu nối giữa ngôn ngữ con người và phần cứng.

---

## 2. DỮ LIỆU & BẢO MẬT (Database & Security)

### database.py - Kết nối MongoDB
*   **AsyncIOMotorClient**: Thư viện dùng để kết nối với cơ sở dữ liệu MongoDB theo cơ chế bất đồng bộ (Asynchronous). Điều này cực kỳ quan trọng vì nó giúp Server xử lý được hàng trăm yêu cầu cùng lúc mà không bị treo khi đợi dữ liệu từ ổ cứng.

### security.py - Mã hóa & Thẻ thành viên
*   **bcrypt**: Thuật toán băm mật khẩu (Hashing). Nó biến mật khẩu thành chuỗi ký tự lạ. Đây là cơ chế bảo mật một chiều: Bạn có thể xay thịt thành giò, nhưng không thể biến giò ngược lại thành thịt.
*   **JWT (JSON Web Token)**: Sau khi đăng nhập thành công, hệ thống cấp một "chiếc thẻ" Token. App Flutter sẽ lưu thẻ này và gửi kèm trong các yêu cầu sau để Server nhận diện người dùng mà không cần nhập lại mật khẩu.

---

## 3. LOGIC NGHIỆP VỤ (API Routers)

### auth.py - Đăng ký & Đăng nhập
*   **Logic OTP**: Khi User yêu cầu, Server sinh mã 6 số ngẫu nhiên, lưu vào một bảng tạm trong DB và gửi mail qua giao thức SMTP. Khi User đăng ký, Server sẽ so khớp mã này để xác thực email thật.
*   **Login Flow**: Kiểm tra sự tồn tại của Email -> So khớp mật khẩu đã băm -> Cấp Token JWT.

### devices.py - Điều khiển thiết bị
*   **Dynamic GPIO**: Đây là tính năng nổi bật. User có thể thêm thiết bị và chọn chân pin bất kỳ trên App. Server sẽ lấy số chân đó, đóng gói vào JSON và gửi qua MQTT. ESP nhận được số nào thì tự động cấu hình chân đó làm OUTPUT để bật/tắt.

### ai_chat.py - Trí tuệ nhân tạo
*   **Llama-3.3-70b (via Groq)**: Bộ não AI chính. Nó được nạp "danh sách thiết bị" hiện có để biết nhà bạn có gì.
*   **System Prompt**: Đóng vai trò là "luật pháp" cho AI. Ép AI nói chuyện kiểu Gen Z nhưng phải trả về kết quả định dạng JSON để máy tính xử lý được.

---

## 4. DỊCH VỤ CHẠY NGẦM (Services)

### mqtt_service.py - Giao tiếp phần cứng & Tự động hóa AI
*   **_on_message**: Tai lắng nghe của Server.
    *   **An ninh AI**: Nếu có người và là ban đêm, AI tự động phân tích độ nguy hiểm để bật còi/đèn báo động.
    *   **Tự động làm mát**: Nếu nhiệt độ quá nóng, AI tự bật quạt và báo cho chủ nhà.
    *   **Đồng bộ nút bấm**: Nếu bạn nhấn nút cứng trên thiết bị, trạng thái trên App sẽ tự đổi màu theo ngay lập tức nhờ luồng dữ liệu này.

### scheduler_service.py - Vòng lặp hẹn giờ
*   **Task Scheduler**: Một tiến trình chạy ngầm quét Database mỗi phút. Nếu giờ hiện tại trùng với giờ hẹn của User, nó sẽ tự động gửi lệnh MQTT để bật/tắt thiết bị.

---

## 5. FIRMWARE (ESP8266 & ESP32-CAM)

### ESP8266 - Điều khiển chính
*   **WiFiManager**: Giúp thiết bị không bị "chết" khi đổi WiFi. Nó sẽ tự phát ra một sóng WiFi tên "SmartHome-Config" để bạn dùng điện thoại vào cài đặt mạng mới.
*   **MQTT Client**: Duy trì kết nối ổn định với Broker HiveMQ để nhận lệnh và gửi dữ liệu cảm biến.

### ESP32-CAM - Giám sát
*   **MJPEG Stream**: Cắt nhỏ video thành hàng nghìn tấm ảnh JPEG gửi liên tục để tạo ra luồng livestream chuyển động mượt mà trên App.
*   **Flash Control**: Nhận lệnh từ MQTT để bật LED siêu sáng trên board, phục vụ quan sát ban đêm.

---

## 6. KHỞI TẠO (Database Seed)

### init_db.py
*   **Mục đích**: Thiết lập "nền móng" cho Database sạch. Tạo các `Index` để tăng tốc độ tìm kiếm và tạo tài khoản `admin@smarthome.com` mặc định để người dùng mới có thể đăng nhập ngay mà không cần cấu hình phức tạp.
