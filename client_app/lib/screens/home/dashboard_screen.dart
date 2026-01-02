import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../automation/schedule_screen.dart'; 
import '../device/share_device_screen.dart'; 

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

  void _changeLanguage(String langCode) => setState(() => _currentLang = langCode);
  void _toggleTheme(bool isDark) => setState(() => _isDarkMode = isDark);
  String tr(String key) => _appData[_currentLang]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    final themeColors = AppThemeColors(_isDarkMode);

    final List<Widget> screens = [
      _HomeTab(lang: _currentLang, tr: tr, theme: themeColors),      
      AutomationTab(lang: _currentLang, tr: tr, theme: themeColors), 
      _AnalyticsTab(lang: _currentLang, tr: tr, theme: themeColors), 
      _SettingsTab(lang: _currentLang, tr: tr, theme: themeColors, onLanguageChanged: _changeLanguage, isDarkMode: _isDarkMode, onThemeChanged: _toggleTheme),  
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
    );
  }
}

// --- TAB 1: HOME ---
class _HomeTab extends StatefulWidget {
  final String lang;
  final Function(String) tr;
  final AppThemeColors theme;
  const _HomeTab({required this.lang, required this.tr, required this.theme});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, bool> deviceStates = {
    "Smart AC": true, "Smart Light": true, "Front Door": true, "Sensor Hub": false,
  };

  void _showAddDeviceDialog() {
    TextEditingController nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
           Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)))),
           const SizedBox(height: 20),
           Text(widget.tr('add_device'), style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
           const SizedBox(height: 20),
           TextField(
             controller: nameController,
             style: TextStyle(color: widget.theme.textMain),
             decoration: InputDecoration(
               hintText: widget.tr('enter_name'),
               hintStyle: TextStyle(color: widget.theme.textSub),
               filled: true,
               fillColor: widget.theme.background,
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
             ),
           ),
           const SizedBox(height: 20),
           SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
             onPressed: () {
               if(nameController.text.isNotEmpty) {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm: ${nameController.text}")));
               }
             }, 
             child: Text(widget.tr('add_now'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
           const SizedBox(height: 30),
        ]),
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
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.tr('welcome'), style: TextStyle(color: widget.theme.textSub, fontSize: 12)), Text("Alex Johnson", style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold))]),
              ]),
              GestureDetector(onTap: _showAddDeviceDialog, child: CircleAvatar(backgroundColor: widget.theme.surface, child: Icon(Icons.add, color: widget.theme.primary))),
          ]),
          const SizedBox(height: 24),
          Row(children: [Expanded(child: _buildEnvCard(widget.tr('temp'), "24", "°C", Icons.thermostat, Colors.orange)), const SizedBox(width: 16), Expanded(child: _buildEnvCard(widget.tr('hum'), "45", "%", Icons.water_drop, Colors.blue))]),
          const SizedBox(height: 24),
          Text(widget.tr('my_devices'), style: TextStyle(color: widget.theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 0.85, mainAxisSpacing: 16, crossAxisSpacing: 16,
            children: [
              _buildDeviceCard("Smart AC", "Living Room", Icons.ac_unit, deviceStates["Smart AC"]!, Colors.blue, "Smart AC"),
              _buildDeviceCard("Smart Light", "Bedroom", Icons.lightbulb, deviceStates["Smart Light"]!, Colors.yellow, "Smart Light"),
              _buildDeviceCard("Front Door", "Entrance", Icons.lock, deviceStates["Front Door"]!, widget.theme.primary, "Front Door"),
              _buildDeviceCard("Sensor Hub", "Kitchen", Icons.sensors_off, false, Colors.grey, "Sensor Hub"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEnvCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.theme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(title, style: TextStyle(color: widget.theme.textSub, fontSize: 12)), RichText(text: TextSpan(children: [TextSpan(text: value, style: TextStyle(color: widget.theme.textMain, fontSize: 24, fontWeight: FontWeight.bold)), TextSpan(text: unit, style: TextStyle(color: widget.theme.textSub, fontSize: 16))]))]),
    );
  }

  Widget _buildDeviceCard(String name, String room, IconData icon, bool isOn, Color color, String key) {
    return GestureDetector(
      onTap: () => setState(() => deviceStates[key] = !deviceStates[key]!),
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
                  leading: const Icon(Icons.share, color: AppColors.primary),
                  title: Text("Chia sẻ thiết bị", style: TextStyle(color: widget.theme.textMain)),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ShareDeviceScreen(deviceName: name)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: Text("Cài đặt thiết bị", style: TextStyle(color: widget.theme.textMain)),
                  onTap: () { Navigator.pop(context); },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Xóa thiết bị", style: TextStyle(color: Colors.red)),
                  onTap: () { Navigator.pop(context); },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isOn ? color.withOpacity(0.5) : Colors.transparent, width: 2), boxShadow: widget.theme.isDark ? [] : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: isOn ? color : Colors.grey, size: 30), Switch(value: isOn, onChanged: (v) => setState(() => deviceStates[key] = v), activeColor: color)]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(color: widget.theme.textMain, fontWeight: FontWeight.bold, fontSize: 16)), Text(room, style: TextStyle(color: widget.theme.textSub, fontSize: 12)), const SizedBox(height: 4), Text(isOn ? "On" : "Off", style: TextStyle(color: isOn ? color : Colors.grey, fontWeight: FontWeight.bold))])
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

  const _SettingsTab({required this.lang, required this.tr, required this.onLanguageChanged, required this.theme, required this.isDarkMode, required this.onThemeChanged});

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
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.theme.border)), child: Row(children: [Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.theme.primary), color: Colors.grey[800]), child: const Icon(Icons.person, color: Colors.white, size: 30)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Nguyễn Văn A", style: TextStyle(color: widget.theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)), Text("admin@aiot.vn", style: TextStyle(color: widget.theme.textSub, fontSize: 14))])])),
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