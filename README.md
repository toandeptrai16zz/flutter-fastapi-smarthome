# 🏠 Nhà thông minh IoT - Đồ án AIoT

## Thông tin đồ án

- **Sinh viên thực hiện:** Hà Quang Chương
- **Lớp:** D17DT&KTMT1 - Khóa D17
- **Ngành:** Công nghệ Kỹ thuật Điện tử Viễn thông
- **Trường:** Đại học Điện lực (EPU)
- **Thành phần dự án:** Ứng dụng di động (Client App) cho Hệ thống nhà thông minh AIoT

---

## 🚀 Báo cáo tiến độ

**Tính đến ngày: 02/01/2026**

Ứng dụng client được phát triển bằng **Flutter**, tập trung vào **Giao diện người dùng hiện đại (Modern UI)**, **Trải nghiệm người dùng (UX)** mượt mà và khả năng tương thích đa nền tảng. Hiện tại, giao diện frontend và logic xử lý cục bộ đã **hoàn thiện 100%**.

---

## ✅ Các tính năng đã hoàn thiện

### 🔐 Xác thực & Quản lý người dùng
- [x] **Màn hình Đăng nhập:** Giao diện hiện đại, hỗ trợ chế độ Dark/Light.
- [x] **Quên mật khẩu:** Thiết kế theo phong cách Glassmorphism (kính mờ) với hiệu ứng phát sáng.
- [x] **Đăng nhập mạng xã hội:** Tích hợp giao diện đăng nhập với Google.
- [x] **Điều hướng:** Logic chuyển đổi mượt mà giữa các màn hình.

### 📱 Bảng điều khiển chính
- [x] **Thanh điều hướng dưới cùng:** Bốn tab truy cập nhanh: Trang chủ, Lịch trình, Thống kê và Cài đặt.
- [x] **Tab Trang chủ:**
    - Hiển thị dữ liệu cảm biến môi trường (Nhiệt độ, Độ ẩm).
    - Lưới thiết bị với trạng thái Bật/Tắt thời gian thực.
    - **Tương tác:** Chạm để bật/tắt thiết bị, nhấn giữ để mở menu tùy chọn.
- [x] **Tab Thống kê:** Biểu đồ cột trực quan hóa mức tiêu thụ điện hàng tuần.
- [x] **Tab Cài đặt:** Tùy chọn chuyển đổi ngôn ngữ (VI/EN) và bật/tắt thông báo.

### ⚙️ Chức năng nâng cao
- [x] **Tự động hóa & Lịch trình:**
    - Xem danh sách các tác vụ tự động.
    - Thêm, sửa và xóa lịch trình thông qua một bottom sheet chuyên nghiệp.
    - **Thành phần giao diện:** Sử dụng Cupertino Picker (bộ chọn kiểu cuộn của iOS) để chọn thời gian và bộ chọn ngày tùy chỉnh để lặp lại hàng tuần.
    - **Điều khiển bằng cử chỉ:** Chức năng vuốt để xóa (Dismissible).
- [x] **Chia sẻ thiết bị:**
    - Giao diện quản lý thành viên gia đình và quyền truy cập.
    - **Phân quyền dựa trên vai trò:** Gán các vai trò như Chủ sở hữu (Admin), Điều khiển (Control), hoặc Chỉ xem (View).
    - Phản hồi trực quan với hiệu ứng "Glow" trên các thiết bị được chia sẻ.
- [x] **Quản lý giao diện (Theme):**
    - Đã triển khai đầy đủ chế độ Dark Mode và Light Mode.
    - Toàn bộ giao diện ứng dụng (nền, chữ, biểu tượng, popup) tự động thay đổi dựa trên cài đặt của người dùng.

---

## 🛠 Cấu trúc dự án

Dự án tuân theo một cấu trúc thư mục rõ ràng và có khả năng mở rộng để tách biệt các thành phần (Giao diện, logic và dịch vụ).

```
lib/
├── main.dart                 # Điểm khởi đầu của ứng dụng
├── theme/
│   └── app_theme.dart        # Quản lý giao diện và màu sắc (Dark/Light)
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart           # Giao diện Đăng nhập
│   │   └── forgot_password_screen.dart # Giao diện Quên mật khẩu
│   ├── home/
│   │   └── dashboard_screen.dart       # Màn hình chính điều phối các tab
│   ├── automation/
│   │   └── schedule_screen.dart        # Quản lý lịch trình (Thêm/Sửa/Xóa)
│   └── device/
│       └── share_device_screen.dart    # Giao diện chia sẻ thiết bị
└── ... (Các thư mục khác cho models, services, widgets)
```

---

## 📸 Điểm nổi bật

| Tính năng             | Trạng thái      | Phong cách / Tương tác chính    |
|-----------------------|-----------------|---------------------------------|
| **Màn hình Đăng nhập**| Đã hoàn thiện   | Phong cách Glassmorphism        |
| **Bảng điều khiển**   | Đã hoàn thiện   | Tương tác nhấn giữ (Long Press) |
| **Màn hình Tự động hóa**| Đã hoàn thiện   | Bộ chọn thời gian kiểu iOS      |
| **Chia sẻ thiết bị**  | Đã hoàn thiện   | Phân quyền dựa trên vai trò     |

---

## 📝 Kế hoạch tiếp theo

- **Phát triển Backend (Server Python):**
    - Xây dựng API server bằng Flask hoặc FastAPI.
    - Tích hợp cơ sở dữ liệu để quản lý người dùng và trạng thái thiết bị.
- **Tích hợp phần cứng IoT:**
    - Lập trình vi điều khiển ESP32/ESP8266.
    - Thiết lập giao tiếp bằng MQTT hoặc WebSockets.
- **Đồng bộ hóa thời gian thực:**
    - Triển khai cập nhật trạng thái thời gian thực giữa ứng dụng di động và thiết bị IoT.

> "Dự án đang trong quá trình phát triển. Các tính năng và giao diện có thể thay đổi trong các phiên bản tương lai."
