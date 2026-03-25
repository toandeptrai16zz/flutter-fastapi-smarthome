import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  // Gửi lệnh Bật/Tắt
  static Future<bool> toggleDevice(String deviceId, bool status) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/device/update'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "device_id": deviceId,
          "status": status
        }),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        print("toggleDevice lỗi: status=${response.statusCode} body=${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi kết nối Server (toggle): $e");
      return false;
    }
  }

  // Lấy trạng thái hiện tại
  static Future<bool> getStatus(String deviceId) async {
    try {
      final response = await http.get(Uri.parse('${Constants.baseUrl}/device/$deviceId'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['status'];
      }
    } catch (e) {
      print("Lỗi kết nối Server: $e");
    }
    return false;
  }
}