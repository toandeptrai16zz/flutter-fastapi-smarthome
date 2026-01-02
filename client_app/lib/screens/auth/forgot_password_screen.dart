import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Tự động phát hiện chế độ tối/sáng từ hệ thống hoặc settings
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = AppThemeColors(isDark);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header (Nút Back)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new, color: theme.textMain),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Hero Icon (Glass Effect + Glow)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Hiệu ứng phát sáng (Glow)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Icon chính (Glass)
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.05), // Glass background
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset, // Icon chuẩn Material Symbols
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 3. Headline Text
              Text(
                "Quên mật khẩu?",
                style: TextStyle(
                  color: theme.textMain,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Body Text
              Text(
                "Đừng lo lắng. Hãy nhập email hoặc số điện thoại gắn liền với tài khoản của bạn để nhận mã xác nhận.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textSub,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // 5. Input Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Email hoặc Số điện thoại",
                    style: TextStyle(
                      color: theme.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border),
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: TextStyle(color: theme.textMain),
                      decoration: InputDecoration(
                        hintText: "vidu@email.com",
                        hintStyle: TextStyle(color: theme.textSub),
                        prefixIcon: Icon(Icons.mail_outline, color: theme.textSub),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 6. Action Button (Gửi mã)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic giả lập gửi mã
                    if (_emailController.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã gửi mã xác nhận về Email!")),
                      );
                      // Navigator.pop(context); // Nếu muốn quay lại luôn thì bỏ comment dòng này
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: const Text(
                    "Gửi mã xác nhận",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 7. Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Bạn nhớ mật khẩu? ",
                    style: TextStyle(color: theme.textSub),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Đăng nhập ngay",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}