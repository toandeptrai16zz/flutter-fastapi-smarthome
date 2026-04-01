# Walkthrough: Dynamic GPIO Mapping & AI Control 2.0 🚀

Hệ thống đã được nâng cấp lên kiến trúc **Dynamic GPIO Mapping**, cho phép bạn tự do gán chân phần cứng từ App mà không cần sửa code ESP32.

## 🌟 Các Thay Đổi Chính

### 1. Backend (FastAPI)
- **Pin Pool Manager**: Quản lý danh sách các chân GPIO an toàn (`D1, D2, D5, D6, D7, D8`).
- **Available Pins API**: Endpoint mới `GET /devices/available-pins` cung cấp danh sách chân còn trống cho App.
- **Generic MQTT Protocol**: Chuyển từ topic riêng biệt sang 1 topic chung `smarthome/esp/gpio/control` với dữ liệu dạng JSON: `{"pin": 14, "action": "on"}`.

### 2. Mobile App (Flutter)
- **Pin Selection Dropdown**: Khi thêm thiết bị, bạn có thể chọn chân GPIO thực tế từ danh sách. Các chân đang bận sẽ bị mờ đi.
- **Pin Label UI**: Trên mỗi thẻ thiết bị ở Dashboard, nhãn chân (ví dụ: `D5`) sẽ hiển thị nhỏ gọn ở góc dưới để bạn dễ nhận biết.

### 3. Firmware (ESP8266/NodeMCU)
- **Smart Controller 2.0**: Firmware giờ đây trở thành một bộ điều khiển "vô tri" nhưng thông minh. Nó chỉ nhận lệnh JSON và thực thi `digitalWrite` lên chân pin tương ứng.
- **No Reflash Needed**: Bạn chỉ cần nạp code này **MỘT LẦN DUY NHẤT**.

---

## 🛠 Hướng Dẫn Kiểm Thử

1. Thêm đèn gán chân **D5 (GPIO 14)** trên App.
2. Bấm bật/tắt trên Dashboard.
3. Ra lệnh AI: *"Nhà ơi, bật đèn"*.
4. Kiểm tra ESP32 thực thi lệnh.
