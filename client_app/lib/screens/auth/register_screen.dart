import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../home/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;

  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Email hợp lệ để nhận mã.")));
      return;
    }

    setState(() => _isSendingOtp = true);

    final result = await AuthService.sendOtp(email);

    setState(() {
      _isSendingOtp = false;
      if (result['success']) {
        _otpSent = true;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] ? "Đã gửi mã, vui lòng kiểm tra hộp thư." : "Lỗi gửi mã OTP")),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final pass = _passController.text.trim();

    if (name.isEmpty || email.isEmpty || otp.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đầy đủ tất cả các trường!")));
      return;
    }
    
    setState(() => _isLoading = true);
    
    final result = await AuthService.register(email, name, pass, otp);
    
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng ký thành công!"), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Lỗi đăng ký"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = AppThemeColors(isDark);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tạo Tài Khoản", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textMain)),
              const SizedBox(height: 8),
              Text("Chào mừng bạn gia nhập thế giới AIoT đằng cấp.", style: TextStyle(color: theme.textSub, fontSize: 14)),
              const SizedBox(height: 32),

              _buildTextField(Icons.person_outline, "Họ và Tên", _nameController, theme),
              const SizedBox(height: 16),
              
              // Cụm Email + Nút Gửi OTP
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(Icons.email_outlined, "Email (Bắt buộc)", _emailController, theme),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56, // Cho bằng với chiều cao của ô input
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSendingOtp ? null : _sendOtp,
                      child: _isSendingOtp
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Gửi OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              if (_otpSent) ...[
                _buildTextField(Icons.domain_verification, "Mã OTP (6 chữ số trong Email)", _otpController, theme, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
              ],
              
              _buildTextField(Icons.lock_outline, "Mật khẩu", _passController, theme, isPassword: true),
              const SizedBox(height: 40),

              // NÚT ĐĂNG KÝ
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Hoàn Tất Đăng Ký", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint, TextEditingController controller, AppThemeColors theme, {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border), 
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
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
