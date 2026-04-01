import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  // Lấy baseUrl từ Constants
  static String get baseUrl => '${Constants.baseUrl}/api/auth';

  // Headers dùng chung - quan trọng khi dùng Ngrok/LocalTunnel
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    'Bypass-Tunnel-Reminder': 'true',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Lỗi gửi OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String email, String fullName, String password, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'full_name': fullName,
          'password': password,
          'otp_code': otpCode
        }),
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', data['access_token']);
          if (data['email'] != null) await prefs.setString('user_email', data['email']);
          if (data['full_name'] != null) await prefs.setString('user_name', data['full_name']);
        }
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Lỗi đăng ký'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi rớt mạng: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Lưu cache token JWT
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        if (data['email'] != null) await prefs.setString('user_email', data['email']);
        if (data['full_name'] != null) await prefs.setString('user_name', data['full_name']);
        return {'success': true, 'message': 'Đăng nhập thành công', 'token': data['access_token']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Sai email hoặc mật khẩu'};
      }
    } catch (e) {
       return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }
}
