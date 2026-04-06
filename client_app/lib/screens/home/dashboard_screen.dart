import 'package:flutter/material.dart';
import 'dart:async'; // Bổ sung thư viện cho Timer
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../automation/schedule_screen.dart'; 
import '../device/share_device_screen.dart'; 
import '../../services/api_service.dart'; // Import API Service
import '../../services/websocket_service.dart'; // Import WebSocket Realtime
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart'; // Import thư viện Mjpeg

// Dữ liệu từ điển đa ngôn ngữ
final Map<String, Map<String, String>> _appData = {
  'vi': {
    'nav_home': 'Trang chủ', 'nav_auto': 'Lịch trình', 'nav_analytics': 'Thống kê', 'nav_settings': 'Cài đặt',
    'welcome': 'Chào mừng', 'my_devices': 'Thiết bị của tôi', 'temp': 'Nhiệt độ', 'hum': 'Độ ẩm',
    'auto_title': 'Lịch trình', 'today': 'Hôm nay', 'evening': 'Buổi tối',
    'analytics_title': 'Thống kê', 'total_power': 'Tổng điện năng', 'weekly_usage': 'Tiêu thụ tuần này', 'device_usage': 'Thiết bị tiêu thụ',
    'settings_title': 'Cài đặt', 'general': 'CHUNG', 'push_notif': 'Thông báo đẩy', 'language': 'Ngôn ngữ', 'theme': 'Chế độ tối',
    'device': 'THIẾT BỊ', 'ai_config': 'Cấu hình AI', 'automation': 'Tự động hóa', 'logout': 'Đăng xuất',
    'confirm_logout': 'Bạn có chắc chắn muốn đăng xuất không?', 'cancel': 'Hủy', 'add_device': 'Thêm thiết bị', 'enter_name': 'Nhập tên thiết bị...', 'add_now': 'Thêm ngay',
    'add_schedule': 'Tạo lịch trình mới', 'save_schedule': 'Lưu lịch trình', 'delete_schedule': 'Đã xóa lịch trình',
    'repeat': 'Lặp lại', 'action': 'Hành động', 'smart_socket': 'Ổ cắm thông minh', 'turn_on': 'BẬT nguồn',
    'task_name': 'Tên tác vụ',
  },
  'en': {
    'nav_home': 'Home', 'nav_auto': 'Automation', 'nav_analytics': 'Analytics', 'nav_settings': 'Settings',
    'welcome': 'Welcome Home', 'my_devices': 'My Devices', 'temp': 'Temp', 'hum': 'Humidity',
    'auto_title': 'Automation', 'today': 'Today', 'evening': 'Evening',
    'analytics_title': 'Analytics', 'total_power': 'Total Power', 'weekly_usage': 'Weekly Usage', 'device_usage': 'Device Consumption',
    'settings_title': 'Settings', 'general': 'GENERAL', 'push_notif': 'Push Notification', 'language': 'Language', 'theme': 'Dark Mode',
    'device': 'DEVICE', 'ai_config': 'AI Configuration', 'automation': 'Automation', 'logout': 'Log Out',
    'confirm_logout': 'Are you sure you want to log out?', 'cancel': 'Cancel', 'add_device': 'Add Device', 'enter_name': 'Enter device name...', 'add_now': 'Add Now',
    'add_schedule': 'New Schedule', 'save_schedule': 'Save Schedule', 'delete_schedule': 'Schedule deleted',
    'repeat': 'Repeat', 'action': 'Action', 'smart_socket': 'Smart Socket', 'turn_on': 'Turn ON',
    'task_name': 'Task Name',
  }
};

// --- MÀN HÌNH CHÍNH DASHBOARD ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _currentLang = 'vi';
  bool _isDarkMode = true;
  String _userName = "";
  String _userEmail = "";

  void _changeLanguage(String langCode) => setState(() => _currentLang = langCode);
  void _toggleTheme(bool isDark) => setState(() => _isDarkMode = isDark);
  String tr(String key) => _appData[_currentLang]?[key] ?? key;

  // --- AI VOICE ASSISTANT STATE ---
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _spokenText = "";
  String _aiReply = "";
  bool _isProcessingAI = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Khách";
      _userEmail = prefs.getString('user_email') ?? "guest@aiot.vn";
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.1); // Giọng trầm bổng nhẹ
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_spokenText.isNotEmpty && !_isProcessingAI) {
              _processVoiceCommand(_spokenText);
            }
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        // Kiểm tra xem thiết bị có hỗ trợ tiếng Việt không
        bool hasVietnamese = false;
        try {
          var locales = await _speech.locales();
          hasVietnamese = locales.any(
            (l) => l.localeId.toLowerCase().contains('vi'),
          );
        } catch (_) {}

        if (!hasVietnamese) {
          // Hiển thị hướng dẫn cài gói tiếng Việt
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Row(children: [
                  Icon(Icons.mic_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("Chưa có giọng tiếng Việt",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ]),
                content: const Text(
                  "Thiết bị chưa cài gói nhận dạng giọng nói tiếng Việt.\n\n"
                  "Cách khắc phục:\n"
                  "1. Vào Cài đặt → Quản lý chung → Ngôn ngữ\n"
                  "2. Thêm Tiếng Việt vào danh sách\n"
                  "3. Vào Google → Nhận dạng giọng nói → Tải về Tiếng Việt\n\n"
                  "Trong lúc chờ, bạn có thể dùng nút MIC để GÕ LỆNH thay thế.",
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Đã hiểu", style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ],
              ),
            );
          }
          return;
        }

        setState(() {
          _isListening = true;
          _spokenText = "";
          _aiReply = "";
        });
        var locales = await _speech.locales();
        debugPrint("STT Locales không định dạng @@");
        for(var l in locales){
          debugPrint("${l.localeId} - ${l.name}");

        }

        String targetLocale = "vi-VN";
        final viLocale = locales.firstWhere(
          (l) => l.localeId.toLowerCase().contains('vi'),
          orElse: () => locales.first, // fallback
        );
        targetLocale = viLocale.localeId; // dùng đúng ID thiết bị báo
        debugPrint("=== Using locale: $targetLocale ===");

        _speech.listen(
          onResult: (val) => setState(() {
            _spokenText = val.recognizedWords;
          }),
          localeId: targetLocale,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    setState(() {
      _isProcessingAI = true;
      _aiReply = "Đang xử lý...";
      _spokenText = text; // Hiển thị text người dùng đã gõ hoặc nói
    });
    
    // Gửi Voice text lên Backend AI
    var result = await ApiService.sendVoiceCommand(text);
    
    if (result != null && result.containsKey('reply')) {
      setState(() {
        _aiReply = result['reply'];
        _isProcessingAI = false;
        _spokenText = ""; // Reset text sau khi xong
      });
      await _flutterTts.speak(result['reply']);
    } else {
      setState(() {
        _aiReply = "Xin lỗi, tổng đài AI đang bận.";
        _isProcessingAI = false;
      });
      await _flutterTts.speak("Xin lỗi, tổng đài AI đang bận.");
    }
  }
  
  // Tính năng ẩn (Gõ chữ) dự phòng cho máy ảo bị hỏng Micro
  void _showTextCommandDialog() {
    TextEditingController _textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Gõ lệnh giả giọng nói"),
          content: TextField(
            controller: _textController,
            decoration: const InputDecoration(hintText: "Ví dụ: bật đèn phòng ngủ"),
            autofocus: true,
            onSubmitted: (text) {
              Navigator.pop(context);
              if (text.isNotEmpty) _processVoiceCommand(text);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_textController.text.isNotEmpty) {
                  _processVoiceCommand(_textController.text);
                }
              },
              child: const Text("Gửi đi"),
            ),
          ],
        );
      },
    );
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    final themeColors = AppThemeColors(_isDarkMode);

    final List<Widget> screens = [
      _HomeTab(lang: _currentLang, tr: tr, theme: themeColors, userName: _userName),      
      AutomationTab(lang: _currentLang, tr: tr, theme: themeColors), 
      _AnalyticsTab(lang: _currentLang, tr: tr, theme: themeColors), 
      _SettingsTab(lang: _currentLang, tr: tr, theme: themeColors, onLanguageChanged: _changeLanguage, isDarkMode: _isDarkMode, onThemeChanged: _toggleTheme, userName: _userName, userEmail: _userEmail),  
    ];

    return Scaffold(
      backgroundColor: themeColors.background,
      body: SafeArea(child: IndexedStack(index: _selectedIndex, children: screens)),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: themeColors.surface,
        selectedItemColor: themeColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: tr('nav_home')),
          BottomNavigationBarItem(icon: const Icon(Icons.smart_toy), label: tr('nav_auto')),
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: tr('nav_analytics')),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: tr('nav_settings')),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        heroTag: "ai_mic_btn", // Tránh lỗi crash Hero tag duplicate
        onPressed: _showTextCommandDialog, // Ấn 1 lần để gõ chữ thay vì nói
        backgroundColor: Colors.transparent,
        elevation: _isListening ? 15 : 5,
        child: GestureDetector(
          onLongPress: _listen,
          onLongPressUp: () {
              if (_isListening) {
                  _speech.stop();
                  setState(() => _isListening = false);
              }
          },
          child: Container(
            width: 65, height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isListening || _isProcessingAI 
                    ? [Colors.purple, Colors.pink] 
                    : [themeColors.primary, Colors.lightBlue]
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isProcessingAI ? Icons.hourglass_top : Icons.mic, color: Colors.white, size: 28),
                if (_isListening) const Text("Nói", style: TextStyle(color: Colors.white, fontSize: 8)),
              ],
            ),
          ),
        ),
      ) : null,
      bottomSheet: _aiReply.isNotEmpty || _spokenText.isNotEmpty ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_spokenText.isNotEmpty)
              Text("Bạn: \"$_spokenText\"", style: TextStyle(color: themeColors.textSub, fontStyle: FontStyle.italic)),
            if (_aiReply.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Nhà: $_aiReply", style: TextStyle(color: themeColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            const SizedBox(height: 10),
            Align(
               alignment: Alignment.centerRight,
               child: TextButton(onPressed: () => setState(() { _aiReply = ""; _spokenText = ""; }), child: const Text("Đóng"))
            )
          ],
        ),
      ) : null,
    );
  }
}

// --- TAB 1: HOME ---
class _HomeTab extends StatefulWidget {
  final String lang;
  final Function(String) tr;
  final AppThemeColors theme;
  final String userName;
  const _HomeTab({required this.lang, required this.tr, required this.theme, required this.userName});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool isLoading = true;
  String currentTemp = "--";
  String currentHum = "--";
  StreamSubscription? _wsSubscription;

  // 🔥 DYNAMIC: Danh sách thiết bị lấy từ MongoDB, không hardcode nữa!
  List<Map<String, dynamic>> devices = [];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _loadAllDevices();
    _connectWebSocket();
  }

  void _requestNotificationPermission() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void _connectWebSocket() {
    final ws = WebSocketService();
    ws.connect();
    _wsSubscription = ws.stream.listen((payload) {
      if (!mounted) return;
      final String event = payload['event'] ?? payload['type'] ?? 'unknown';
      final data = payload['data'] ?? payload;
      
      if (event == 'sensor') {
        setState(() {
          currentTemp = data['temperature']?.toString() ?? currentTemp;
          currentHum = data['humidity']?.toString() ?? currentHum;
        });
      } else if (event == 'device_update') {
        final deviceId = data['device_id'] as String?;
        final status = data['status'] as bool? ?? false;
        final idx = devices.indexWhere((d) => d['device_id'] == deviceId);
        if (idx != -1) setState(() => devices[idx]['status'] = status);
      } else if (event == 'ai_alert') {
        final message = data['message'] as String? ?? "AI Alert";
        final deviceId = data['device_id'] as String?;
        final status = data['status'] as bool? ?? true;
        final alertType = data['alert_type'] as String? ?? "info";

        if (deviceId != null && deviceId != "none") {
            final idx = devices.indexWhere((d) => d['device_id'] == deviceId);
            if (idx != -1) setState(() => devices[idx]['status'] = status);
        }

        if (alertType == "security") {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: 100,
                channelKey: 'alerts_channel',
                actionType: ActionType.Default,
                title: '🚨 KHẨN CẤP: AI An Ninh',
                body: message,
              )
            );
        } else {
            _showAITalkDialog(message);
        }
      } else if (event == 'device_added') {
        final deviceId = data['device_id'] as String?;
        if (deviceId != null && !devices.any((d) => d['device_id'] == deviceId)) {
          setState(() => devices.add(Map<String, dynamic>.from(data)));
        }
      } else if (event == 'device_deleted') {
        setState(() => devices.removeWhere((d) => d['device_id'] == data['device_id']));
      } else if (event == 'device_updated') {
        final deviceId = data['device_id'] as String?;
        final idx = devices.indexWhere((d) => d['device_id'] == deviceId);
        if (idx != -1) {
          setState(() {
            devices[idx]['name'] = data['name'] ?? devices[idx]['name'];
            devices[idx]['room'] = data['room'] ?? devices[idx]['room'];
            devices[idx]['type'] = data['type'] ?? devices[idx]['type'];
            devices[idx]['is_inverted'] = data['is_inverted'] ?? devices[idx]['is_inverted'];
          });
        }
      } else if (event == 'init') {
        final sensor = data['sensor'] as Map<String, dynamic>?;
        if (sensor != null) {
          currentTemp = sensor['temperature']?.toString() ?? currentTemp;
          currentHum = sensor['humidity']?.toString() ?? currentHum;
        }
        final devList = data['devices'] as List<dynamic>?;
        if (devList != null) {
          setState(() {
            devices = devList.map((d) => Map<String, dynamic>.from(d as Map)).toList();
            isLoading = false;
          });
        }
      }
    });
  }

  void _showAITalkDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.surface,
        title: Row(children: [const Icon(Icons.smart_toy, color: Colors.blue), const SizedBox(width: 8), Text("Trợ lý AI", style: TextStyle(color: widget.theme.textMain))]),
        content: Text(message, style: TextStyle(color: widget.theme.textSub)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đã hiểu"))]
      )
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _loadAllDevices() async {
    var allDevices = await ApiService.getAllDevices();
    var sensorData = await ApiService.getSensorData();
    if (mounted) {
      setState(() {
        devices = allDevices;
        if (sensorData != null) {
          currentTemp = sensorData['temperature']?.toString() ?? "--";
          currentHum = sensorData['humidity']?.toString() ?? "--";
        }
        isLoading = false;
      });
    }
  }

  void _toggleDevice(String deviceId, bool newState) async {
    final idx = devices.indexWhere((d) => d['device_id'] == deviceId);
    if (idx == -1) return;
    
    // Kiểm tra firmware trước khi điều khiển
    final hasFw = devices[idx]['has_firmware'] as bool? ?? true;
    if (!hasFw) {
      _showAITalkDialog("Ôi bạn ơi! Thiết bị này được thêm trên App cho vui vậy thôi chứ chưa có code phần cứng (Firmware) trên ESP32 đâu. Nhớ nạp code cho nó nhé! 😉");
      return; 
    }

    setState(() => devices[idx]['status'] = newState);
    bool success = await ApiService.toggleDevice(deviceId, newState);
    if (!success && mounted) {
      setState(() => devices[idx]['status'] = !newState);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi! Không bật tắt được.")));
    }
  }

  // Map type → icon
  IconData _getIcon(String? type) {
    switch (type) {
      case 'light': return Icons.lightbulb;
      case 'fan': return Icons.mode_fan_off;
      case 'ac': return Icons.ac_unit;
      case 'door': return Icons.lock;
      case 'curtain': return Icons.curtains;
      case 'sensor': return Icons.sensors;
      case 'tv': return Icons.tv;
      default: return Icons.devices;
    }
  }

  // Map type → color
  Color _getColor(String? type) {
    switch (type) {
      case 'light': return Colors.orange;
      case 'fan': return Colors.lightGreen;
      case 'ac': return Colors.blue;
      case 'door': return Colors.cyan;
      case 'curtain': return Colors.purple;
      case 'tv': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showCameraStream() async {
    // Hiển thị dialog loading trước
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: widget.theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.cyanAccent),
              const SizedBox(height: 16),
              Text("Đang tìm Camera...", style: TextStyle(color: widget.theme.textMain)),
            ],
          ),
        ),
      ),
    );

    // Gọi API lấy IP Camera động
    final camData = await ApiService.getCameraStatus();
    if (!mounted) return;
    Navigator.pop(context); // Đóng loading

    if (camData == null || camData['success'] != true) {
      // Không tìm thấy Camera
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: widget.theme.surface,
          title: Row(children: [
            const Icon(Icons.videocam_off, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text("Camera Offline", style: TextStyle(color: widget.theme.textMain)),
          ]),
          content: Text(
            "Chưa tìm thấy ESP32-CAM nào!\n\n"
            "Hãy chắc chắn:\n"
            "• ESP32-CAM đã được nạp firmware NexHome\n"
            "• Đã kết nối cùng mạng WiFi\n"
            "• MQTT broker đang hoạt động",
            style: TextStyle(color: widget.theme.textSub),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đã hiểu"))],
        ),
      );
      return;
    }

    final String streamUrl = camData['url'];
    final String camIp = camData['ip'];
    bool flashOn = false;

    // Hiển thị Camera Stream
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: widget.theme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.videocam, color: Colors.cyanAccent),
                      const SizedBox(width: 8),
                      Text("Camera An Ninh", style: TextStyle(color: widget.theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    IconButton(
                      icon: Icon(Icons.close, color: widget.theme.textSub),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                // IP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text("LIVE • $camIp", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(height: 12),
                // Video Stream
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Mjpeg(
                      isLive: true,
                      stream: streamUrl,
                      fit: BoxFit.cover,
                      error: (context, error, stack) => const Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.signal_wifi_off, color: Colors.redAccent, size: 48),
                          SizedBox(height: 8),
                          Text("Mất kết nối Camera", style: TextStyle(color: Colors.redAccent)),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Flash Control Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        setDialogState(() => flashOn = !flashOn);
                        await ApiService.controlCameraFlash(flashOn);
                      },
                      icon: Icon(flashOn ? Icons.flash_on : Icons.flash_off, color: flashOn ? Colors.yellow : Colors.white70),
                      label: Text(flashOn ? "Flash: BẬT" : "Flash: TẮT", style: TextStyle(color: flashOn ? Colors.yellow : Colors.white70)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: flashOn ? Colors.amber.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDeviceDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController idController = TextEditingController();
    String selectedRoom = "Phòng Khách";
    String selectedType = "light";
    int? selectedPin;
    List<Map<String, dynamic>> availablePins = [];
    bool isLoadingPins = true;
    
    bool isInverted = false;
    
    final rooms = ["Phòng Khách", "Phòng Ngủ", "Nhà Bếp", "Sân Vườn", "Phòng Tắm", "Entrance"];
    final types = {"light": "Đèn", "fan": "Quạt", "ac": "Điều Hòa", "door": "Cửa/Khóa", "curtain": "Rèm Cửa", "tv": "TV", "sensor": "Cảm Biến"};

    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Chỉ fetch 1 lần khi dialog mở
          if (isLoadingPins && availablePins.isEmpty) {
             ApiService.getAvailablePins().then((pins) {
                if (context.mounted) {
                  setSheetState(() {
                    availablePins = pins;
                    isLoadingPins = false;
                    try {
                      selectedPin = pins.firstWhere((p) => !p['is_used'])['pin'];
                    } catch (_) {}
                  });
                }
             });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
               Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)))),
               const SizedBox(height: 20),
               Text(widget.tr('add_device'), style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
               TextField(
                 controller: nameController,
                 style: TextStyle(color: widget.theme.textMain),
                 decoration: InputDecoration(hintText: "Tên thiết bị (VD: Đèn Phòng Ngủ)", hintStyle: TextStyle(color: widget.theme.textSub), filled: true, fillColor: widget.theme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
               ),
               const SizedBox(height: 12),
               TextField(
                 controller: idController,
                 style: TextStyle(color: widget.theme.textMain),
                 decoration: InputDecoration(hintText: "Device ID (VD: led_3, ac_1)", hintStyle: TextStyle(color: widget.theme.textSub), filled: true, fillColor: widget.theme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
               ),
               const SizedBox(height: 12),
               // Dropdown chọn phòng
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12),
                 decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(12)),
                 child: DropdownButton<String>(
                   value: selectedRoom, isExpanded: true, underline: const SizedBox(),
                   dropdownColor: widget.theme.surface,
                   style: TextStyle(color: widget.theme.textMain),
                   items: rooms.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                   onChanged: (v) => setSheetState(() => selectedRoom = v!),
                 ),
               ),
               const SizedBox(height: 12),
               // Dropdown chọn loại
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12),
                 decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(12)),
                 child: DropdownButton<String>(
                   value: selectedType, isExpanded: true, underline: const SizedBox(),
                   dropdownColor: widget.theme.surface,
                   style: TextStyle(color: widget.theme.textMain),
                   items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Row(children: [Icon(_getIcon(e.key), color: _getColor(e.key), size: 20), const SizedBox(width: 8), Text(e.value)]))).toList(),
                   onChanged: (v) => setSheetState(() => selectedType = v!),
                 ),
               ),
               const SizedBox(height: 12),
               // Dropdown chọn Chân phần cứng (GPIO)
               isLoadingPins 
                ? const Center(child: CircularProgressIndicator())
                : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.theme.primary.withOpacity(0.3))),
                  child: DropdownButton<int>(
                    value: selectedPin, isExpanded: true, underline: const SizedBox(),
                    dropdownColor: widget.theme.surface,
                    style: TextStyle(color: widget.theme.textMain),
                    hint: Text("Chọn chân phần cứng (GPIO)", style: TextStyle(color: widget.theme.textSub, fontSize: 13)),
                    items: availablePins.map((p) => DropdownMenuItem<int>(
                      value: p['pin'], 
                      enabled: !p['is_used'],
                      child: Text("${p['label']} ${p['is_used'] ? '(Đang dùng)' : '(Trống)'}", style: TextStyle(color: p['is_used'] ? Colors.grey : widget.theme.textMain))
                    )).toList(),
                    onChanged: (v) => setSheetState(() => selectedPin = v),
                  ),
                ),
               const SizedBox(height: 12),
               // Switch chọn Active Low
               SwitchListTile(
                 title: Text("Mức thấp (Active Low)", style: TextStyle(color: widget.theme.textMain, fontSize: 14)),
                 subtitle: Text("Bật khi xuất mức LOW (Relay/LED NodeMCU)", style: TextStyle(color: widget.theme.textSub, fontSize: 11)),
                 value: isInverted,
                 activeColor: widget.theme.primary,
                 onChanged: (v) => setSheetState(() => isInverted = v),
               ),
               const SizedBox(height: 20),
               SizedBox(width: double.infinity, child: ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                 onPressed: () async {
                   if (nameController.text.isNotEmpty && idController.text.isNotEmpty) {
                     final id = idController.text.trim();
                     final name = nameController.text.trim();
                     final messenger = ScaffoldMessenger.of(context);
                     
                     Navigator.pop(context);
                     
                     bool ok = await ApiService.createDevice({
                       "device_id": id,
                       "name": name,
                       "type": selectedType,
                       "room": selectedRoom,
                       "gpio_pin": selectedPin,
                       "is_inverted": isInverted,
                     });
                     
                     if (ok) {
                       _loadAllDevices();
                       messenger.showSnackBar(SnackBar(content: Text("✅ Đã thêm: $name (Pin: $selectedPin)")));
                     } else {
                       messenger.showSnackBar(const SnackBar(content: Text("❌ Lỗi! Có thể ID hoặc Pin đã tồn tại.")));
                     }
                   }
                 },
                 child: Text(widget.tr('add_now'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
               )),
               const SizedBox(height: 30),
            ]),
          );
        },
      ),
    );
  }

  void _showEditDeviceDialog(Map<String, dynamic> device) {
    TextEditingController nameController = TextEditingController(text: device['name'] ?? "");
    String selectedRoom = device['room'] ?? "Phòng Khách";
    String selectedType = device['type'] ?? "light";
    String deviceId = device['device_id'];
    bool isInverted = device['is_inverted'] ?? false;
    
    final rooms = ["Phòng Khách", "Phòng Ngủ", "Nhà Bếp", "Sân Vườn", "Phòng Tắm", "Entrance"];
    final types = {"light": "Đèn", "fan": "Quạt", "ac": "Điều Hòa", "door": "Cửa/Khóa", "curtain": "Rèm Cửa", "tv": "TV", "sensor": "Cảm Biến"};

    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
             Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)))),
             const SizedBox(height: 20),
             Text("Chỉnh sửa thiết bị", style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Text("ID: $deviceId", style: TextStyle(color: widget.theme.textSub, fontSize: 12)),
             const SizedBox(height: 16),
             TextField(
               controller: nameController,
               autofocus: true,
               style: TextStyle(color: widget.theme.textMain),
               decoration: InputDecoration(labelText: "Tên thiết bị", labelStyle: TextStyle(color: widget.theme.primary), filled: true, fillColor: widget.theme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
             ),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12),
               decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(12)),
               child: DropdownButton<String>(
                 value: selectedRoom, isExpanded: true, underline: const SizedBox(),
                 dropdownColor: widget.theme.surface,
                 style: TextStyle(color: widget.theme.textMain),
                 items: rooms.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                 onChanged: (v) => setSheetState(() => selectedRoom = v!),
               ),
             ),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12),
               decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(12)),
               child: DropdownButton<String>(
                 value: selectedType, isExpanded: true, underline: const SizedBox(),
                 dropdownColor: widget.theme.surface,
                 style: TextStyle(color: widget.theme.textMain),
                 items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Row(children: [Icon(_getIcon(e.key), color: _getColor(e.key), size: 20), const SizedBox(width: 8), Text(e.value)]))).toList(),
                 onChanged: (v) => setSheetState(() => selectedType = v!),
               ),
             ),
             const SizedBox(height: 12),
             // Switch chọn Active Low cho Edit
             SwitchListTile(
               title: Text("Mức thấp (Active Low)", style: TextStyle(color: widget.theme.textMain, fontSize: 14)),
               subtitle: Text("Bật khi xuất mức LOW (Relay/LED NodeMCU)", style: TextStyle(color: widget.theme.textSub, fontSize: 11)),
               value: isInverted,
               activeColor: widget.theme.primary,
               onChanged: (v) => setSheetState(() => isInverted = v),
             ),
             const SizedBox(height: 20),
             SizedBox(width: double.infinity, child: ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
               onPressed: () async {
                 if (nameController.text.isNotEmpty) {
                   Navigator.pop(context);
                   bool ok = await ApiService.updateDevice(deviceId, {
                     "name": nameController.text.trim(),
                     "type": selectedType,
                     "room": selectedRoom,
                     "is_inverted": isInverted,
                   });
                   if (ok) {
                     if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Đã cập nhật: ${nameController.text}")));
                     }
                   } else {
                     if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Lỗi cập nhật thiết bị!")));
                     }
                   }
                 }
               },
               child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
             )),
             const SizedBox(height: 30),
           ]),
         ),
       ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                  Container(width: 45, height: 45, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.theme.surface, border: Border.all(color: widget.theme.primary)), child: Icon(Icons.person, color: widget.theme.textMain)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.tr('welcome'), style: TextStyle(color: widget.theme.textSub, fontSize: 12)), Text(widget.userName, style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold))]),
              ]),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showCameraStream, 
                    child: CircleAvatar(backgroundColor: widget.theme.surface, child: const Icon(Icons.videocam, color: Colors.cyanAccent))
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showAddDeviceDialog, 
                    child: CircleAvatar(backgroundColor: widget.theme.surface, child: Icon(Icons.add, color: widget.theme.primary))
                  ),
                ],
              ),
          ]),
          const SizedBox(height: 24),
          Row(children: [Expanded(child: _buildEnvCard(widget.tr('temp'), currentTemp, "°C", Icons.thermostat, Colors.orange)), const SizedBox(width: 16), Expanded(child: _buildEnvCard(widget.tr('hum'), currentHum, "%", Icons.water_drop, Colors.blue))]),
          const SizedBox(height: 24),
          Text(widget.tr('my_devices'), style: TextStyle(color: widget.theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // 🔥 DYNAMIC: Gom nhóm thiết bị theo Phòng
          devices.isEmpty && !isLoading
            ? Center(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.devices_other, size: 60, color: widget.theme.textSub),
                  const SizedBox(height: 12),
                  Text("Chưa có thiết bị nào", style: TextStyle(color: widget.theme.textSub, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Bấm nút + để thêm thiết bị mới", style: TextStyle(color: widget.theme.textSub, fontSize: 12)),
                ]),
              ))
            : Column(children: _buildGroupedDevices()),
        ],
      ),
    );
  }

  // 🔥 Gom nhóm thiết bị theo Phòng, mỗi phòng có header + grid riêng
  List<Widget> _buildGroupedDevices() {
    // Nhóm thiết bị theo room
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final d in devices) {
      final room = (d['room'] as String?)?.isNotEmpty == true ? d['room'] as String : 'Khác';
      grouped.putIfAbsent(room, () => []);
      grouped[room]!.add(d);
    }

    final List<Widget> widgets = [];
    final roomIcons = {
      'Phòng Khách': Icons.weekend, 'Phòng Ngủ': Icons.bed,
      'Nhà Bếp': Icons.kitchen, 'Sân Vườn': Icons.yard,
      'Phòng Tắm': Icons.bathtub, 'Entrance': Icons.door_front_door,
    };

    grouped.forEach((room, devicesInRoom) {
      // Header phòng
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: widget.theme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(roomIcons[room] ?? Icons.room, color: widget.theme.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Text(room, style: TextStyle(color: widget.theme.textMain, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: widget.theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text("${devicesInRoom.length}", style: TextStyle(color: widget.theme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      );

      // Grid 2 cột cho mỗi phòng
      widgets.add(
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.05, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemCount: devicesInRoom.length,
          itemBuilder: (context, index) {
            final d = devicesInRoom[index];
            final deviceId = d['device_id'] as String? ?? '';
            final name = d['name'] as String? ?? deviceId;
            final type = d['type'] as String? ?? 'unknown';
            final isOn = d['status'] as bool? ?? false;
            final hasFw = d['has_firmware'] as bool? ?? true;
            final pinLabel = d['pin_label'] as String?;
            return _buildDeviceCard(name, room, _getIcon(type), isOn, _getColor(type), deviceId, hasFw: hasFw, pinLabel: pinLabel);
          },
        ),
      );
      widgets.add(const SizedBox(height: 8));
    });

    return widgets;
  }

  Widget _buildEnvCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.theme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(title, style: TextStyle(color: widget.theme.textSub, fontSize: 12)), RichText(text: TextSpan(children: [TextSpan(text: value, style: TextStyle(color: widget.theme.textMain, fontSize: 24, fontWeight: FontWeight.bold)), TextSpan(text: unit, style: TextStyle(color: widget.theme.textSub, fontSize: 16))]))]),
    );
  }

  Widget _buildDeviceCard(String name, String room, IconData icon, bool isOn, Color color, String deviceId, {bool hasFw = true, String? pinLabel}) {
    return GestureDetector(
      onTap: () {
        if (!hasFw) {
          showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Cảnh báo"), content: const Text("Thiết bị này chưa cập nhật firmware, có thể không hoạt động ổn định."), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
        } else {
          _toggleDevice(deviceId, !isOn);
        }
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: widget.theme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(name, style: TextStyle(color: widget.theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: Text("Chỉnh sửa thiết bị", style: TextStyle(color: widget.theme.textMain)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDeviceDialog(devices.firstWhere((d) => d['device_id'] == deviceId));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: AppColors.primary),
                  title: Text("Chia sẻ thiết bị", style: TextStyle(color: widget.theme.textMain)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ShareDeviceScreen(deviceName: name)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Xóa thiết bị", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    bool ok = await ApiService.deleteDevice(deviceId);
                    if (ok) {
                      messenger.showSnackBar(SnackBar(content: Text("🗑️ Đã xóa: $name")));
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isOn ? color.withOpacity(0.5) : Colors.transparent, width: 2), boxShadow: widget.theme.isDark ? [] : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isOn ? color : Colors.grey, size: 24),
                if (!hasFw) Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: const Icon(Icons.priority_high, color: Colors.white, size: 8),
                  ),
                ),
              ],
            ),
            Transform.scale(scale: 0.8, child: Switch(value: isOn, onChanged: (v) => _toggleDevice(deviceId, v), activeColor: color)),
          ]),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Flexible(child: Text(name, style: TextStyle(color: widget.theme.textMain, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (!hasFw) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 12)),
            ]),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isOn ? "On" : "Off", style: TextStyle(color: isOn ? color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                if (pinLabel != null) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: widget.theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(pinLabel, style: TextStyle(color: widget.theme.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ])),
        ]),
      ),
    );
  }
}

// --- TAB 3: ANALYTICS ---
class _AnalyticsTab extends StatelessWidget {
  final String lang;
  final Function(String) tr;
  final AppThemeColors theme;
  const _AnalyticsTab({required this.lang, required this.tr, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: Text(tr('analytics_title'), style: TextStyle(color: theme.textMain)), backgroundColor: theme.background, centerTitle: true, automaticallyImplyLeading: false, iconTheme: IconThemeData(color: theme.icon)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primary.withOpacity(0.8), theme.primary.withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('total_power'), style: const TextStyle(color: Colors.white70)), const SizedBox(height: 8), const Text("42.5 kWh", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))]), const Icon(Icons.bolt, color: Colors.yellow, size: 40)])),
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.border)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(tr('weekly_usage'), style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold)), const Icon(Icons.calendar_today, color: Colors.grey, size: 16)]), const SizedBox(height: 30), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [_buildBar("T2", 40, false), _buildBar("T3", 60, false), _buildBar("T4", 30, false), _buildBar("T5", 90, true), _buildBar("T6", 50, false), _buildBar("T7", 70, false), _buildBar("CN", 45, false)])])),
            const SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: Text(tr('device_usage'), style: TextStyle(color: theme.textMain, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            _buildUsageItem("Smart AC", "15.2 kWh", Icons.ac_unit, Colors.blue),
            _buildUsageItem("Smart Light", "4.1 kWh", Icons.lightbulb, Colors.yellow),
            _buildUsageItem("Kitchen Hub", "8.5 kWh", Icons.kitchen, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, bool isHigh) {
    return Column(children: [Container(width: 12, height: height, decoration: BoxDecoration(color: isHigh ? theme.primary : (theme.isDark ? Colors.grey[700] : Colors.grey[300]), borderRadius: BorderRadius.circular(4))), const SizedBox(height: 8), Text(day, style: TextStyle(color: theme.textSub, fontSize: 10))]);
  }
  Widget _buildUsageItem(String name, String usage, IconData icon, Color color) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Expanded(child: Text(name, style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold))), Text(usage, style: TextStyle(color: theme.textSub))]));
  }
}

// --- TAB 4: SETTINGS ---
class _SettingsTab extends StatefulWidget {
  final String lang;
  final Function(String) tr;
  final Function(String) onLanguageChanged;
  final AppThemeColors theme;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final String userName;
  final String userEmail;

  const _SettingsTab({required this.lang, required this.tr, required this.onLanguageChanged, required this.theme, required this.isDarkMode, required this.onThemeChanged, required this.userName, required this.userEmail});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _notifEnabled = true;
  bool _automationEnabled = false;

  void _handleLogout() {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: widget.theme.surface, title: Text(widget.tr('logout'), style: TextStyle(color: widget.theme.textMain)), content: Text(widget.tr('confirm_logout'), style: TextStyle(color: widget.theme.textSub)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.tr('cancel'), style: const TextStyle(color: Colors.grey))), TextButton(onPressed: () {Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));}, child: Text(widget.tr('logout'), style: const TextStyle(color: Colors.red)))]));
  }

  void _showLanguagePicker() {
    showModalBottomSheet(context: context, backgroundColor: widget.theme.surface, builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Text("🇻🇳", style: TextStyle(fontSize: 24)), title: Text("Tiếng Việt", style: TextStyle(color: widget.theme.textMain)), trailing: widget.lang == 'vi' ? Icon(Icons.check, color: widget.theme.primary) : null, onTap: () {widget.onLanguageChanged('vi'); Navigator.pop(context);}),
        ListTile(leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)), title: Text("English", style: TextStyle(color: widget.theme.textMain)), trailing: widget.lang == 'en' ? Icon(Icons.check, color: widget.theme.primary) : null, onTap: () {widget.onLanguageChanged('en'); Navigator.pop(context);}),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.background,
      appBar: AppBar(title: Text(widget.tr('settings_title'), style: TextStyle(color: widget.theme.textMain)), backgroundColor: widget.theme.background, centerTitle: true, automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.theme.border)), child: Row(children: [Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.theme.primary), color: Colors.grey[800]), child: const Icon(Icons.person, color: Colors.white, size: 30)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.userName, style: TextStyle(color: widget.theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)), Text(widget.userEmail, style: TextStyle(color: widget.theme.textSub, fontSize: 14))])])),
          const SizedBox(height: 24),
          _buildSection(widget.tr('general')),
          _buildItem(Icons.notifications, widget.tr('push_notif'), hasSwitch: true, value: _notifEnabled, onChanged: (v) => setState(() => _notifEnabled = v), color: Colors.blue),
          _buildItem(Icons.language, widget.tr('language'), trailing: widget.lang == 'vi' ? "Tiếng Việt" : "English", onTap: _showLanguagePicker, color: Colors.orange),
          _buildItem(Icons.dark_mode, widget.tr('theme'), hasSwitch: true, value: widget.isDarkMode, onChanged: (val) => widget.onThemeChanged(val), color: Colors.purple),
          const SizedBox(height: 20),
          _buildSection(widget.tr('device')),
          _buildItem(Icons.smart_toy, widget.tr('ai_config'), color: Colors.green),
          _buildItem(Icons.bolt, widget.tr('automation'), hasSwitch: true, value: _automationEnabled, onChanged: (v) => setState(() => _automationEnabled = v), color: Colors.cyan),
          const SizedBox(height: 30),
          OutlinedButton(onPressed: _handleLogout, style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.logout, color: Colors.red), const SizedBox(width: 8), Text(widget.tr('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
        ],
      ),
    );
  }

  Widget _buildSection(String title) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 5), child: Text(title, style: TextStyle(color: widget.theme.textSub, fontWeight: FontWeight.bold, fontSize: 12)));

  Widget _buildItem(IconData icon, String title, {bool hasSwitch = false, bool value = false, ValueChanged<bool>? onChanged, String? trailing, VoidCallback? onTap, Color color = Colors.grey}) {
    return GestureDetector(
      onTap: hasSwitch ? () => onChanged?.call(!value) : onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 16), Expanded(child: Text(title, style: TextStyle(color: widget.theme.textMain, fontSize: 16))), if (hasSwitch) Switch(value: value, onChanged: onChanged, activeColor: widget.theme.primary) else if (trailing != null) Row(children: [Text(trailing, style: TextStyle(color: widget.theme.textSub)), Icon(Icons.chevron_right, color: widget.theme.textSub)]) else Icon(Icons.chevron_right, color: widget.theme.textSub)])),
    );
  }
}