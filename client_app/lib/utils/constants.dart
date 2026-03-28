import 'dart:io';

class Constants {
  // ═══ Tự động phát hiện emulator hay điện thoại thật ═══════════════════
  // Emulator Android     → dùng 10.0.2.2 (alias của localhost máy tính)
  // Điện thoại thật      → dùng IP WiFi của máy tính trong cùng mạng
  // ─────────────────────────────────────────────────────────────────────
  static const String _emulatorUrl  = "http://10.0.2.2:8000";
  static const String _realDeviceUrl = "http://10.0.60.35:8000";

  static String get baseUrl {
    // Ép cứng dùng IP của Emulator do bạn đang test trên giả lập
    return "http://10.0.2.2:8000";
  }
}