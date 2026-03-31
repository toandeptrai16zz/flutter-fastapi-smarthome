import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  // Key lưu trữ URL trong bộ nhớ máy
  static const String _keyBaseUrl = "backend_base_url";

  // URL mặc định (Emulator Android)
  static const String _defaultUrl = "http://10.0.2.2:8000";
  
  static String _baseUrl = _defaultUrl;

  // Lấy URL hiện tại
  static String get baseUrl => _baseUrl;

  // Lấy URL WebSocket tương ứng (đổi http -> ws và thêm /ws)
  static String get wsUrl {
    String wsBase = _baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    return '$wsBase/ws';
  }

  // Load URL từ bộ nhớ khi khởi động App
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? _defaultUrl;
    print("🚀 Base URL initialized: $_baseUrl");
  }

  // Cập nhật và lưu URL mới
  static Future<void> updateBaseUrl(String newUrl) async {
    if (newUrl.isEmpty) return;
    
    String formattedUrl = newUrl.trim();

    // Loại bỏ dấu / ở cuối nếu có
    if (formattedUrl.endsWith("/")) {
      formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
    }

    // Đảm bảo có prefix http/https
    if (!formattedUrl.startsWith("http")) {
      formattedUrl = "http://$formattedUrl";
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, formattedUrl);
    _baseUrl = formattedUrl;
    print("✅ Base URL updated to: $_baseUrl");
  }
}