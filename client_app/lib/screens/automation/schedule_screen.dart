import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';

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
  // Dữ liệu mẫu
  List<Map<String, dynamic>> schedules = [
    {
      "time": "07:00", "ampm": "AM", "name": "Đèn phòng khách", "action": "BẬT", 
      "repeat": "Hàng ngày", "icon": Icons.lightbulb, "color": const Color(0xFF137FEC), 
      "isActive": true,
      "rawDays": [true, true, true, true, true, true, true],
      "rawTime": DateTime(2024, 1, 1, 7, 0)
    },
    {
      "time": "08:00", "ampm": "AM", "name": "Điều hòa", "action": "TẮT", 
      "repeat": "Cuối tuần", "icon": Icons.ac_unit, "color": Colors.grey, 
      "isActive": false,
      "rawDays": [true, false, false, false, false, false, true],
      "rawTime": DateTime(2024, 1, 1, 8, 0)
    },
  ];

  List<String> dayLabels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];

  String _getRepeatString(List<bool> days) {
    int count = days.where((e) => e).length;
    if (count == 7) return "Hàng ngày";
    if (count == 0) return "Một lần";
    List<String> activeDays = [];
    for(int i=0; i<7; i++) {
      if(days[i]) activeDays.add(dayLabels[i]);
    }
    return activeDays.join(", ");
  }

  void _deleteSchedule(int index) {
    setState(() => schedules.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.tr('delete_schedule'))));
  }

  void _showScheduleDialog({int? index}) {
    bool isEditMode = index != null;
    Map<String, dynamic>? existingItem = isEditMode ? schedules[index] : null;

    DateTime selectedDateTime = isEditMode 
        ? (existingItem!['rawTime'] as DateTime) 
        : DateTime.now();
    
    List<bool> selectedDays = isEditMode 
        ? List<bool>.from(existingItem!['rawDays']) 
        : [false, true, true, true, true, true, false];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStatePopup) {
            return Container(
              height: 700,
              decoration: BoxDecoration(
                color: widget.theme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(3))),
                  
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditMode ? "Chỉnh sửa lịch trình" : widget.tr('add_schedule'), 
                          style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: widget.theme.textSub)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        // TIME PICKER
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: widget.theme.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: widget.theme.border),
                          ),
                          child: CupertinoTheme(
                            data: CupertinoThemeData(
                              brightness: widget.theme.isDark ? Brightness.dark : Brightness.light,
                              textTheme: CupertinoTextThemeData(
                                dateTimePickerTextStyle: TextStyle(color: widget.theme.textMain, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              initialDateTime: selectedDateTime,
                              use24hFormat: false,
                              onDateTimeChanged: (val) => selectedDateTime = val,
                            ),
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
                        Text(widget.tr('action'), style: TextStyle(color: widget.theme.textSub, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: widget.theme.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.theme.border)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.power, color: Colors.blue)),
                                const SizedBox(width: 12),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(widget.tr('smart_socket'), style: TextStyle(color: widget.theme.textMain, fontWeight: FontWeight.bold)),
                                  Text(widget.tr('turn_on'), style: TextStyle(color: widget.theme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ])
                              ]),
                              Icon(Icons.chevron_right, color: widget.theme.textSub),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // BUTTONS
                        Row(
                          children: [
                            if (isEditMode) 
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.withOpacity(0.1), 
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                      ),
                                      onPressed: () {
                                        setState(() => schedules.removeAt(index));
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.tr('delete_schedule'))));
                                      },
                                      child: const Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),

                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  onPressed: () {
                                    String hour = (selectedDateTime.hour % 12 == 0 ? 12 : selectedDateTime.hour % 12).toString().padLeft(2, '0');
                                    String min = selectedDateTime.minute.toString().padLeft(2, '0');
                                    String ampm = selectedDateTime.hour >= 12 ? "PM" : "AM";
                                    
                                    Map<String, dynamic> newData = {
                                      "time": "$hour:$min",
                                      "ampm": ampm,
                                      "name": isEditMode ? existingItem!['name'] : "Tác vụ mới",
                                      "action": "BẬT",
                                      "repeat": _getRepeatString(selectedDays),
                                      "icon": Icons.power,
                                      "color": Colors.blue,
                                      "isActive": true,
                                      "rawDays": selectedDays,
                                      "rawTime": selectedDateTime
                                    };

                                    setState(() {
                                      if (isEditMode) {
                                        schedules[index] = newData;
                                      } else {
                                        schedules.add(newData);
                                      }
                                    });
                                    Navigator.pop(context);
                                  }, 
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.check, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(isEditMode ? "Cập nhật" : widget.tr('save_schedule'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
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
      appBar: AppBar(title: Text(widget.tr('auto_title'), style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.textMain)), backgroundColor: widget.theme.surface.withOpacity(0.8), elevation: 0, actions: [IconButton(onPressed: () {}, icon: Icon(Icons.search, color: widget.theme.icon)), IconButton(onPressed: () {}, icon: Icon(Icons.more_vert, color: widget.theme.icon))]),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: widget.theme.primary, 
        child: const Icon(Icons.add, size: 28, color: Colors.white)
      ),
      
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final item = schedules[index];
          
          // ✅ QUAN TRỌNG: ĐÃ THÊM LẠI DISMISSIBLE ĐỂ VUỐT XÓA ĐƯỢC
          return Dismissible(
            key: UniqueKey(), // Dùng UniqueKey để tránh lỗi duplicate
            direction: DismissDirection.endToStart, // Chỉ cho vuốt sang trái
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white)
            ),
            onDismissed: (_) => _deleteSchedule(index),
            child: GestureDetector(
              onTap: () => _showScheduleDialog(index: index), // Bấm vào để sửa
              child: _buildScheduleCard(item, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: widget.theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.theme.border)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(item['icon'], color: item['color'])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(item['time'], style: TextStyle(color: widget.theme.textMain, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Text(item['ampm'], style: TextStyle(color: widget.theme.textSub, fontSize: 12, fontWeight: FontWeight.bold))]),
          RichText(text: TextSpan(children: [TextSpan(text: "${item['name']}: ", style: TextStyle(color: widget.theme.textSub)), TextSpan(text: item['action'], style: TextStyle(color: item['color'], fontWeight: FontWeight.bold))])),
          const SizedBox(height: 4),
          Text(item['repeat'], style: TextStyle(color: widget.theme.textSub, fontSize: 12)),
        ])),
        // Switch chặn sự kiện chạm để không kích hoạt sửa khi chỉ bật tắt
        GestureDetector(
          onTap: () {}, 
          child: Switch(value: item['isActive'], onChanged: (v) => setState(() => item['isActive'] = v), activeColor: widget.theme.primary)
        )
      ]),
    );
  }
}