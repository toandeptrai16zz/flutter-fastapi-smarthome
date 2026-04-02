import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AutomationTab extends StatefulWidget {
  final String lang;
  final Function(String) tr;
  final AppThemeColors theme;

  const AutomationTab({
    super.key, 
    required this.lang, 
    required this.tr, 
    required this.theme
  });

  @override
  State<AutomationTab> createState() => _AutomationTabState();
}

class _AutomationTabState extends State<AutomationTab> {
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> allDevices = []; // 🔥 DYNAMIC: danh sách thiết bị từ DB
  bool isLoading = true;

  List<String> dayLabels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

  // Device IDs thực sự có code firmware trên ESP32
  static const List<String> firmwareDeviceIds = ['led_1', 'led_2', 'fan_1'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    allDevices = await ApiService.getAllDevices();
    await _fetchSchedules();
  }

  // Helper: lấy tên thiết bị từ device_id
  String _getDeviceName(String deviceId) {
    final d = allDevices.firstWhere((d) => d['device_id'] == deviceId, orElse: () => {});
    return d.isNotEmpty ? (d['name'] as String? ?? deviceId) : deviceId;
  }

  // Helper: lấy icon từ type
  IconData _getDeviceIcon(String deviceId) {
    final d = allDevices.firstWhere((d) => d['device_id'] == deviceId, orElse: () => {});
    switch (d['type'] as String? ?? '') {
      case 'light': return Icons.lightbulb;
      case 'fan': return Icons.mode_fan_off;
      case 'ac': return Icons.ac_unit;
      case 'door': return Icons.lock;
      default: return Icons.devices;
    }
  }

  // Helper: lấy color từ type
  Color _getDeviceColor(String deviceId) {
    final d = allDevices.firstWhere((d) => d['device_id'] == deviceId, orElse: () => {});
    switch (d['type'] as String? ?? '') {
      case 'light': return Colors.orange;
      case 'fan': return Colors.lightGreen;
      case 'ac': return Colors.blue;
      case 'door': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  // Kiểm tra thiết bị có firmware chưa (Lấy từ dữ liệu Backend thay vì hardcode)
  bool _hasFirmware(String deviceId) {
    final d = allDevices.firstWhere((d) => d['device_id'] == deviceId, orElse: () => {});
    return d['has_firmware'] == true;
  }

  Future<void> _fetchSchedules() async {
    setState(() => isLoading = true);
    var data = await ApiService.getSchedules();
    List<Map<String, dynamic>> mapped = [];
    for (var d in data) {
      String timeStr = d['time'];
      int h = int.parse(timeStr.split(':')[0]);
      int m = int.parse(timeStr.split(':')[1]);
      String ampm = h >= 12 ? "PM" : "AM";
      String time12 = "${(h%12 == 0 ? 12 : h%12).toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}";
      
      List<String> rDays = List<String>.from(d['repeated_days'] ?? []);
      String repeatStr = rDays.isEmpty ? "Một lần" : (rDays.length == 7 ? "Hàng ngày" : rDays.join(", "));
      
      mapped.add({
        "id": d['id'],
        "device_id": d['device_id'],
        "time": time12,
        "ampm": ampm,
        "name": _getDeviceName(d['device_id']),
        "action": d['action'] ? "BẬT" : "TẮT",
        "actionBool": d['action'],
        "repeat": repeatStr,
        "icon": _getDeviceIcon(d['device_id']),
        "color": _getDeviceColor(d['device_id']),
        "isActive": d['is_active'],
        "hasFirmware": _hasFirmware(d['device_id']),
        "rawDays": List.generate(7, (i) => rDays.contains(dayLabels[i])),
        "rawTime": DateTime(2024, 1, 1, h, m)
      });
    }
    if (mounted) setState(() { schedules = mapped; isLoading = false; });
  }

  void _deleteSchedule(int index) async {
    String id = schedules[index]['id'];
    bool ok = await ApiService.deleteSchedule(id);
    if (ok) {
      setState(() => schedules.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.tr('delete_schedule'))));
    } else {
      _fetchSchedules(); // Lỗi thì refresh lại
    }
  }

  void _toggleScheduleState(int index, bool val) async {
    setState(() => schedules[index]['isActive'] = val);
    bool ok = await ApiService.toggleSchedule(schedules[index]['id']);
    if (!ok) {
      setState(() => schedules[index]['isActive'] = !val);
    }
  }

  void _showScheduleDialog({int? index}) async {
    // Luôn tải lại danh sách thiết bị mới nhất từ DB trước khi mở dialog
    allDevices = await ApiService.getAllDevices();
    if (!mounted) return;

    bool isEditMode = index != null;
    Map<String, dynamic>? existingItem = isEditMode ? schedules[index] : null;

    DateTime selectedDateTime = isEditMode ? existingItem!['rawTime'] : DateTime.now();
    List<bool> selectedDays = isEditMode ? List<bool>.from(existingItem!['rawDays']) : [false, false, false, false, false, false, false];
    String selectedDevice = isEditMode
        ? existingItem!['device_id']
        : (allDevices.isNotEmpty ? allDevices.first['device_id'] as String : 'led_1');
    bool selectedAction = isEditMode ? existingItem!['actionBool'] : true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStatePopup) {
            return Container(
              height: 700,
              decoration: BoxDecoration(color: widget.theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(3))),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEditMode ? "Chỉnh sửa lịch trình" : widget.tr('add_schedule'), style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: widget.theme.textSub)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.theme.border)),
                          child: CupertinoTheme(
                            data: CupertinoThemeData(
                              brightness: widget.theme.isDark ? Brightness.dark : Brightness.light,
                              textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(color: widget.theme.textMain, fontSize: 22, fontWeight: FontWeight.bold)),
                            ),
                            child: CupertinoDatePicker(mode: CupertinoDatePickerMode.time, initialDateTime: selectedDateTime, use24hFormat: true, onDateTimeChanged: (val) => selectedDateTime = val),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        Text(widget.tr('repeat'), style: TextStyle(color: widget.theme.textSub, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            return GestureDetector(
                              onTap: () => setStatePopup(() => selectedDays[i] = !selectedDays[i]),
                              child: _buildDayCircle(dayLabels[i], selectedDays[i]),
                            );
                          }),
                        ),

                        const SizedBox(height: 30),
                        Text("Thiết lập thiết bị", style: TextStyle(color: widget.theme.textSub, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.theme.border)),
                          child: Column(
                            children: [
                              DropdownButton<String>(
                                value: allDevices.any((d) => d['device_id'] == selectedDevice) ? selectedDevice : (allDevices.isNotEmpty ? allDevices.first['device_id'] as String : null),
                                dropdownColor: widget.theme.surface,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: allDevices.map((d) {
                                  final id = d['device_id'] as String;
                                  final name = d['name'] as String? ?? id;
                                  final room = d['room'] as String? ?? '';
                                  final hasFw = _hasFirmware(id);
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Row(children: [
                                      Icon(_getDeviceIcon(id), color: _getDeviceColor(id), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text("$name${room.isNotEmpty ? ' ($room)' : ''}", style: TextStyle(color: widget.theme.textMain), overflow: TextOverflow.ellipsis)),
                                      if (!hasFw) Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                        child: const Text("⚠ No FW", style: TextStyle(fontSize: 9, color: Colors.amber)),
                                      ),
                                    ]),
                                  );
                                }).toList(),
                                onChanged: (v) => setStatePopup(() => selectedDevice = v!),
                              ),
                              Divider(color: widget.theme.border),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Hành động:", style: TextStyle(color: widget.theme.textMain)),
                                  Row(
                                    children: [
                                      Text(selectedAction ? "BẬT" : "TẮT", style: TextStyle(color: selectedAction ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                      Switch(value: selectedAction, onChanged: (v) => setStatePopup(() => selectedAction = v), activeColor: Colors.green, inactiveThumbColor: Colors.red),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        Row(
                          children: [
                            if (isEditMode) 
                              Expanded(flex: 1, child: Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () { Navigator.pop(context); _deleteSchedule(index); }, child: const Icon(Icons.delete, color: Colors.red))))),
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  onPressed: () async {
                                    String timeStr = "${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}";
                                    List<String> rDays = [];
                                    for(int i=0; i<7; i++) { if(selectedDays[i]) rDays.add(dayLabels[i]); }
                                    
                                    Map<String, dynamic> payload = {
                                      "device_id": selectedDevice,
                                      "action": selectedAction,
                                      "time": timeStr,
                                      "repeated_days": rDays,
                                      "is_active": true
                                    };

                                    if (isEditMode) {
                                      await ApiService.deleteSchedule(schedules[index]['id']);
                                    }
                                    
                                    bool ok = await ApiService.createSchedule(payload);
                                    Navigator.pop(context);
                                    if (ok) {
                                      _fetchSchedules();
                                    } else {
                                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi tạo lịch trình!")));
                                    }
                                  }, 
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.check, color: Colors.white), const SizedBox(width: 8), Text(isEditMode ? "Cập nhật" : widget.tr('save_schedule'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayCircle(String txt, bool isActive) {
    return Container(
      width: 40, height: 40, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? widget.theme.primary : widget.theme.background),
      child: Text(txt, style: TextStyle(color: isActive ? Colors.white : widget.theme.textSub, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.background,
      appBar: AppBar(title: Text(widget.tr('auto_title'), style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.textMain)), backgroundColor: widget.theme.surface.withOpacity(0.8), elevation: 0, actions: [IconButton(onPressed: _fetchSchedules, icon: Icon(Icons.refresh, color: widget.theme.icon))]),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: widget.theme.primary, 
        child: const Icon(Icons.add, size: 28, color: Colors.white)
      ),
      
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : schedules.isEmpty 
          ? Center(child: Text("Chưa có lịch trình", style: TextStyle(color: widget.theme.textSub)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final item = schedules[index];
                return Dismissible(
                  key: Key(item['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white)
                  ),
                  onDismissed: (_) => _deleteSchedule(index),
                  child: GestureDetector(
                    onTap: () => _showScheduleDialog(index: index),
                    child: _buildScheduleCard(item, index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.theme.border)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(item['icon'], color: item['color'])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(item['time'], style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Text(item['ampm'], style: TextStyle(color: widget.theme.textSub, fontSize: 12, fontWeight: FontWeight.bold))]),
          Row(children: [
            Flexible(child: RichText(text: TextSpan(children: [
              TextSpan(text: "${item['name']} ", style: TextStyle(color: widget.theme.textSub)),
              if (item['pinLabel'] != null) TextSpan(text: "(${item['pinLabel']}): ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
              TextSpan(text: item['action'], style: TextStyle(color: item['color'], fontWeight: FontWeight.bold))
            ]))),
            if (item['hasFirmware'] == false) Padding(padding: const EdgeInsets.only(left: 6), child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: const Text("⚠ Cần FW", style: TextStyle(fontSize: 9, color: Colors.amber)),
            )),
          ]),
          const SizedBox(height: 4),
          Text(item['repeat'], style: TextStyle(color: widget.theme.textSub, fontSize: 12)),
        ])),
        GestureDetector(
          onTap: () {}, 
          child: Switch(value: item['isActive'], onChanged: (v) => _toggleScheduleState(index, v), activeColor: widget.theme.primary)
        )
      ]),
    );
  }
}