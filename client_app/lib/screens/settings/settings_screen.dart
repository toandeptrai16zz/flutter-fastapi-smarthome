import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: AppColors.backgroundDark,
        leading: const Icon(Icons.arrow_back_ios_new, size: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      image: const DecorationImage(
                        image: NetworkImage("https://i.pravatar.cc/150?img=12"), // Ảnh avatar giả
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nguyễn Văn A", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("nguyenvana@aiot.vn", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Section: CHUNG
            _buildSectionHeader("CHUNG"),
            _buildSettingItem(icon: Icons.notifications, title: "Thông báo đẩy", hasSwitch: true, value: true),
            _buildSettingItem(icon: Icons.language, title: "Ngôn ngữ", trailingText: "Tiếng Việt"),
            _buildSettingItem(icon: Icons.dark_mode, title: "Giao diện", trailingText: "Tối"),

            const SizedBox(height: 24),

            // 3. Section: AI & THIẾT BỊ
            _buildSectionHeader("AI & THIẾT BỊ"),
            _buildSettingItem(icon: Icons.smart_toy, title: "Cấu hình AI", subTitle: "Độ nhạy & Phản hồi tự động", iconColor: Colors.green),
            _buildSettingItem(icon: Icons.bolt, title: "Tự động hóa", hasSwitch: true, value: false, iconColor: Colors.blue),
            _buildSettingItem(icon: Icons.admin_panel_settings, title: "Quyền riêng tư", iconColor: Colors.redAccent),

            const SizedBox(height: 24),
            
             // 4. Section: THÔNG TIN
            _buildSectionHeader("THÔNG TIN"),
            _buildSettingItem(icon: Icons.help, title: "Trợ giúp & Hỗ trợ", iconColor: Colors.grey),
            _buildSettingItem(icon: Icons.info, title: "Phiên bản", trailingText: "1.2.0 (Build 405)", iconColor: Colors.grey),
            
            const SizedBox(height: 30),
            
            // 5. Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Text("AIoT System © 2024", style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingItem({
    required IconData icon, 
    required String title, 
    String? subTitle,
    String? trailingText,
    bool hasSwitch = false,
    bool value = false,
    Color iconColor = Colors.orange, // Mặc định cam
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                if (subTitle != null)
                  Text(subTitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (hasSwitch)
            Switch(
              value: value, 
              onChanged: (v) {}, 
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.5),
            )
          else ...[
            if (trailingText != null) Text(trailingText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ]
        ],
      ),
    );
  }
}