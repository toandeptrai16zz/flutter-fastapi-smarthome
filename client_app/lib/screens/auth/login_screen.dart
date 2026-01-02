import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/dashboard_screen.dart'; 
import 'forgot_password_screen.dart'; // Import màn hình quên mật khẩu

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy dữ liệu nhập (nếu cần xử lý logic sau này)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Lấy theme động (Sáng/Tối)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = AppThemeColors(isDark);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // 1. Header & Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.textMain),
                    onPressed: () {}, // Màn hình đầu tiên nên không cần back, hoặc để trống
                  ),
                  Text("Smart Control", style: TextStyle(color: theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48), // Placeholder cân giữa
                ],
              ),
              const SizedBox(height: 40),

              // 2. Logo Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.hub, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              
              // Welcome Text
              Text("Welcome Back", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textMain)),
              const SizedBox(height: 8),
              Text(
                "Quản lý thiết bị AIoT của bạn một cách bảo mật.",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textSub, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // 3. Form Inputs
              _buildTextField(Icons.email_outlined, "user@example.com", _emailController, theme),
              const SizedBox(height: 16),
              _buildTextField(Icons.lock_outline, "123456", _passController, theme, isPassword: true),
              
              // Nút Quên mật khẩu
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text("Quên mật khẩu?", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              // 4. NÚT ĐĂNG NHẬP
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  onPressed: () {
                    // Chuyển trang sang Dashboard
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Đăng nhập", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 5. Divider "Hoặc"
              Row(
                children: [
                  Expanded(child: Divider(color: theme.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Hoặc đăng nhập với", style: TextStyle(color: theme.textSub, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: theme.border)),
                ],
              ),

              const SizedBox(height: 30),

             // 6. NÚT SOCIAL LOGIN (ĐÃ SỬA LOGO GOOGLE CHUẨN)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng Google Login đang phát triển")));
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: theme.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ DÙNG ẢNH MẠNG ĐỂ HIỂN THỊ LOGO ĐA SẮC
                      Image.network(
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png",
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.red), // Nếu mất mạng thì hiện tạm icon cũ
                      ),
                      const SizedBox(width: 12),
                      Text("Tiếp tục với Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textMain)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint, TextEditingController controller, AppThemeColors theme, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border), // Thêm viền mờ cho đẹp
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: theme.textMain),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: theme.textSub),
          hintText: hint,
          hintStyle: TextStyle(color: theme.textSub.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}