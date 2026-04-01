import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/dashboard_screen.dart'; 
import 'forgot_password_screen.dart'; 
import 'register_screen.dart'; // Import màn hình đăng ký
import '../../utils/constants.dart';
import '../../services/auth_service.dart'; // Import AuthService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy dữ liệu nhập
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  bool _isLoading = false;

  void _showServerConfigDialog() {
    final TextEditingController urlController = TextEditingController(text: Constants.baseUrl);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Cấu hình Backend", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nhập URL Server (Localtunnel/Ngrok/IP)", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                hintText: "https://your-domain.loca.lt",
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            const Text("⚠️ Lưu ý: Ví dụ http://192.168.1.10:8000", style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              await Constants.updateBaseUrl(urlController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("🚀 Đã cập nhật thành: ${Constants.baseUrl}")),
                );
              }
            },
            child: const Text("Lưu lại", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _login() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ Email và Mật khẩu")));
      return;
    }

    setState(() => _isLoading = true);
    
    // Gọi API Đăng nhập
    final result = await AuthService.login(email, pass);
    
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(result['message']), backgroundColor: Colors.green)
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(result['message'] ?? 'Lỗi đăng nhập'), backgroundColor: Colors.red)
        );
      }
    }
  }

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
                    onPressed: () {}, 
                  ),
                  Text("Smart Control", style: TextStyle(color: theme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48), 
                ],
              ),
              const SizedBox(height: 40),

              // 2. Logo Box
              GestureDetector(
                onLongPress: _showServerConfigDialog,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.hub, size: 40, color: AppColors.primary),
                ),
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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Đăng nhập", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
              
              // NÚT CHUYỂN SANG ĐĂNG KÝ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Bạn chưa có tài khoản?", style: TextStyle(color: theme.textMain)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text("Đăng ký ngay", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

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

             // 6. NÚT SOCIAL LOGIN 
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
                      Image.network(
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png",
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.red), 
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
        border: Border.all(color: theme.border), 
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