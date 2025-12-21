import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  // Gửi lệnh Bật/Tắt
  static Future<bool> toggleDevice(bool status) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/device/update'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "device_id": Constants.deviceId,
          "status": status
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi: $e");
      return false;
    }
  }

  // Lấy trạng thái hiện tại
  static Future<bool> getStatus() async {
    try {
      final response = await http.get(Uri.parse('${Constants.baseUrl}/status/${Constants.deviceId}'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['status'];
      }
    } catch (e) {
      print("Lỗi: $e");
    }
    return false;
  }
}