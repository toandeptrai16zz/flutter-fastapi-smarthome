# Kế Hoạch Triển Khai: Dynamic GPIO Mapping & AI Control 🚀

## 1. Mục Tiêu
Chuyển đổi từ cơ chế điều khiển cứng (Hardcoded Pins) sang cơ chế điều khiển động (Dynamic Pins). Người dùng có thể thêm thiết bị mới trên App, gán chân GPIO trên ESP32 mà không cần nạp lại code firmware.

## 2. Giải Pháp Cho Các Câu Hỏi Của Bạn

### Q1: Làm sao để biết thiết bị mới dùng chân nào để code?
- **Cơ chế**: Hệ thống sẽ quản lý một **Pin Pool** (Danh sách các chân trống). Khi thêm thiết bị, App hiển thị danh sách các chân GPIO còn trống trên ESP32 (ví dụ: D1, D2, D5, D6...).
- **Cắm dây**: Sau khi chọn chân trên App (ví dụ: D5), ông chỉ cần cắm Relay/LED vào đúng chân D5 trên ESP32 là nó sẽ chạy theo đúng tên ông đã đặt.

### Q2: Nếu có sẵn chân nhưng chưa dùng thì nó tự gán hay mình chọn?
- **Tùy chọn**:
    - **Tự động**: Backend tự tìm chân GPIO còn trống đầu tiên để gán (Dễ nhất cho ông).
    - **Thủ công**: Người dùng chọn chân cụ thể từ danh sách Dropdown trên App (Nếu ông muốn cắm dây theo ý thích).
- **Pin Pool**: Một danh sách các chân "an toàn" của NodeMCU/ESP32 sẽ được định nghĩa sẵn trong Backend (tránh các chân đặc biệt như TX/RX).

### Q3: Con AI có tắt/bật được tất cả thiết bị không?
- **Chắc chắn 100%!** Quy trình xử lý của AI:
    1. Người dùng nói: *"Nhà ơi bật đèn tủ lạnh"*.
    2. AI xử lý và trả về JSON: `{"device_id": "den_tu_lanh", "status": true}`.
    3. Backend kiểm tra Database, thấy `den_tu_lanh` đang được gán vào **GPIO 14** (chân D5).
    4. Backend lập tức gửi lệnh MQTT: `{"pin": 14, "action": "on"}`.
    5. ESP32 nhận lệnh, bóc tách JSON và thực hiện `digitalWrite(14, HIGH)`.

---

## 3. Kiến Trúc Chi Tiết

### 3.1. Database (MongoDB)
Cập nhật Schema cho collection `devices`:
```json
{
  "device_id": "den_p_ngu",
  "name": "Đèn Phòng Ngủ",
  "type": "light",
  "room": "Phòng Ngủ",
  "gpio_pin": 14,           // Chân GPIO thực tế trên ESP32 (D5)
  "pin_mode": "OUTPUT",     // OUTPUT (Thiết bị) hoặc INPUT (Cảm biến)
  "has_firmware": true,
  "status": false
}
```

### 3.2. Giao Thức MQTT Mới (Generic Payload)
Thay vì topic riêng cho từng ID, ta dùng 1 topic chung cho toàn bộ lệnh điều khiển pin:
- **Topic**: `smarthome/esp/gpio/control`
- **Payload**: `{"pin": 14, "action": "on"}`

### 3.3. Firmware ESP32 (Phần cứng)
- ESP32 sẽ nhận lệnh JSON thay vì chỉ nhận chuỗi "ON/OFF".
- Nó bóc tách số Pin trong payload để điều khiển.
- **Ưu điểm**: Ông chỉ cần nạp firmware **MỘT LẦN DUY NHẤT** cho ESP32. Sau này thêm bao nhiêu đèn, bao nhiêu quạt cũng không cần sửa code C++ nữa.

---

## 4. Các Bước Thực Hiện

### Bước 1: Cấu hình Pin Pool (Backend)
- Định nghĩa danh sách chân GPIO khả dụng (D1, D2, D5, D6, D7...).
- Viết API `GET /devices/available-pins` để App lấy danh sách chân trống.

### Bước 2: Nâng cấp App Flutter
- Thêm Dropdown chọn chân phần cứng (GPIO) trong màn hình **"Thêm thiết bị"**.
- Hiển thị danh sách chân trống từ API.

### Bước 3: Logic Điều Khiển Thông Minh (Backend)
- Cập nhật hàm điều khiển để ánh xạ thông minh từ `device_id` -> `gpio_pin`.
- Tích hợp vào AI Chat để AI tự tra cứu chân GPIO trước khi ra lệnh.

### Bước 4: Firmware ESP32 - Phiên bản 2.0
- Sử dụng thư viện `ArduinoJson` trên ESP32.
- Nhận diện pin động và điều khiển `digitalWrite`.

---

## 5. Kế Hoạch Kiểm Tra
1. Thêm đèn 1 (Chân D2), quạt 1 (Chân D5) trên App.
2. Bấm nút trên App -> Kiểm tra điện áp chân D2/D5.
3. Ra lệnh AI "Bật quạt 1" -> Kiểm tra chân D5 phản hồi.
4. Xóa thiết bị -> Chân GPIO đó phải quay lại trạng thái "Trống" để cho thiết bị khác dùng.

---
**Tình trạng**: ⏳ Đang chờ người dùng phê duyệt kế hoạch để triển khai. 🚀
