import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ShareDeviceScreen extends StatefulWidget {
  final String deviceName;
  const ShareDeviceScreen({super.key, required this.deviceName});

  @override
  State<ShareDeviceScreen> createState() => _ShareDeviceScreenState();
}

class _ShareDeviceScreenState extends State<ShareDeviceScreen> {
  String _selectedRole = 'view';
  final TextEditingController _emailController = TextEditingController();

  List<Map<String, String>> members = [
    {"name": "Bạn (Tôi)", "email": "admin@example.com", "role": "admin"},
    {"name": "Nguyễn Thu Hà", "email": "ha.nguyen@example.com", "role": "control"},
    {"name": "Trần Minh Tuấn", "email": "tuan.tran@example.com", "role": "view"},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = AppThemeColors(isDark);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Chia sẻ thiết bị", style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: theme.background,
        iconTheme: IconThemeData(color: theme.textMain),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: theme.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DEVICE CONTEXT CARD
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
              ),
              child: Stack(
                children: [
                  // SỬA LỖI TẠI ĐÂY: Xóa cái filter sai cú pháp, chỉ dùng màu mờ
                  Positioned(
                    top: -20, right: -20, 
                    child: Container(
                      width: 100, height: 100, 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        color: AppColors.primary.withOpacity(0.2)
                      )
                    )
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.deviceName, style: TextStyle(color: theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.active, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text("Phòng khách • Online", style: TextStyle(color: theme.textSub, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: theme.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.camera_indoor, size: 40, color: theme.textSub),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. INVITE SECTION
            Text("Mời thành viên mới", style: TextStyle(color: theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email hoặc số điện thoại", style: TextStyle(color: theme.textSub, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.border)),
                    child: TextField(
                      controller: _emailController,
                      style: TextStyle(color: theme.textMain),
                      decoration: InputDecoration(
                        hintText: "vd: user@example.com",
                        hintStyle: TextStyle(color: theme.textSub.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        suffixIcon: Icon(Icons.person_add, color: theme.textSub),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text("Quyền hạn", style: TextStyle(color: theme.textSub, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: theme.background, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        _buildRoleOption("view", "Chỉ xem", theme),
                        _buildRoleOption("control", "Điều khiển", theme),
                        _buildRoleOption("admin", "Quản trị", theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi lời mời!")));
                      },
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Gửi lời mời", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.send, color: Colors.white, size: 18)]),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. MEMBER LIST
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Danh sách thành viên", style: TextStyle(color: theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text("${members.length} Users", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
            ]),
            const SizedBox(height: 12),
            Column(
              children: members.map((m) => _buildMemberItem(m, theme)).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(String value, String label, AppThemeColors theme) {
    bool isSelected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Text(label, style: TextStyle(color: isSelected ? AppColors.primary : theme.textSub, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildMemberItem(Map<String, String> member, AppThemeColors theme) {
    bool isMe = member['role'] == 'admin' && member['name']!.contains("Bạn");
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.transparent : theme.surface,
        border: Border.all(color: isMe ? AppColors.primary.withOpacity(0.3) : theme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.grey[300], child: const Icon(Icons.person, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member['name']!, style: TextStyle(color: theme.textMain, fontWeight: FontWeight.bold)),
                    if(isMe) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)), child: const Text("CHỦ SỞ HỮU", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                  ],
                ),
                Text(member['email']!, style: TextStyle(color: theme.textSub, fontSize: 12)),
              ],
            ),
          ),
          if(!isMe) IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.grey)),
        ],
      ),
    );
  }
}