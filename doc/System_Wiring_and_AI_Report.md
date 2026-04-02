# 📄 Báo Cáo Cấu Hình Phần Cứng ESP32 & Bản Vá Khắc Phục Lỗi AI

**Ngày tạo:** 02/04/2026

## 1. Sơ Đồ Đấu Nối Cảm Biến & Nút Bấm Trên ESP32 NodeMCU
Theo mã nguồn `firmware_esp32/src/main.cpp` hiện hành, hệ thống được quy hoạch các chân vật lý như sau để đảm bảo hoạt động an toàn và đồng bộ với giao diện phần mềm:
- **Cảm biến khí hậu DHT11**: Chân truyền dữ liệu (Data) đấu vào **D1** (GPIO 5). Cấp 3.3V và GND để vận hành đọc tín hiệu mỗi 10 giây.
- **Cảm biến chuyển động PIR**: Chân tín hiệu ra (Out) đấu vào **D2** (GPIO 4).
- **Nút Bấm 1 (Điều khiển tĩnh cho Relay 1)**: Cắm 1 chân vào **D5** (GPIO 14), chân còn lại nối với **GND**. Firmware đã sử dụng cấu hình chống nhiễu `INPUT_PULLUP` nên không kích hoạt nguồn VCC trực tiếp vào nút nhấn.
- **Nút Bấm 2 (Điều khiển tĩnh cho Relay 2)**: Cắm 1 chân vào **D6** (GPIO 12), chân còn lại nối với **GND**.
- **Relay 1 (Mạch đóng ngắt 1)**: Nối chân tín hiệu IN vào **D3** (GPIO 0).
- **Relay 2 (Mạch đóng ngắt 2)**: Nối chân tín hiệu IN vào **D4** (GPIO 2). (Lưu ý: D4 có đèn LED built-in và sử dụng trạng thái mặc định kích Active Low tự nhiên ở một số mô đun rơle).

## 2. Giải Quyết Vấn Đề Lỗi Luồng AI Tự Giải Quyết (Hallucination Ảo Giác Thiết Bị)
**📌 Mô tả sự cố:**
Mô hình ngôn ngữ `Llama-3.3-70b-versatile` trước đó có hiện tượng "ảo giác logic điều kiện" - nghĩa là khi nhận dữ liệu nhiệt độ cao (VD > 31°C) qua Chat, nó bị khuynh hướng tự nghĩ ra lệnh `[Bật Quạt]` hoặc `[Bật Máy Lạnh]` nhằm mục đích làm hài lòng người dùng. Thậm chí cả khi trong nhà hiện tại *KHÔNG ĐĂNG KÝ* bất kỳ quạt nào trên CSDL MongoDB. Điều này tạo ra ID chết, gửi MQTT vô ích, dẫn đến chu kỳ Crash và rối loạn hệ thống.

**✅ Giải pháp & Khắc Phục:**
Bổ sung `KỶ LUẬT THÉP VỀ THIẾT BỊ` thẳng vào Prompt hệ thống của Llama tại file `server_backend/app/api/routers/ai_chat.py`. Trợ lý ảo được chỉ dẫn lại với chế độ kiểm soát bắt buộc:
1. AI phải mapping (nối dữ liệu) hoàn toàn với mảng `{device_list_str}`.
2. Từ chối yêu cầu một cách chân thật nếu thiết bị không tồn tại, kết hợp sử dụng ngôn từ GenZ để làm dịu người dùng (Ví dụ: *"Nóng thế nhờ, mà tiếc là nhà mình chưa decor cái quạt nào, hỏng thể bật được 🥲"*).
3. Đưa cơ chế bắt trả về mảng `[]` cho key `device_id` nếu nhận thức được không có lệnh nào hợp lệ để gửi đi.

**🎯 Kết Quả Nhận Được:** Toàn bộ hệ thống giờ đã khép kín hoàn toàn. An toàn từ logic phần cứng (Nút nhấn PULLUP) đến trí não ở Tầng Máy chủ. Crash loop đã bị xóa bỏ.
