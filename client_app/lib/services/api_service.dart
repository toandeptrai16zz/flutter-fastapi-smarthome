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

  // Lấy dữ liệu cảm biến mới nhất
  static Future<Map<String, dynamic>?> getSensorData() async {
    try {
      final response = await http.get(Uri.parse('${Constants.baseUrl}/sensors/latest')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi lấy dữ liệu cảm biến: $e");
    }
    return null;
  }

  // Lấy danh sách lịch trình
  static Future<List<dynamic>> getSchedules() async {
    try {
      final response = await http.get(Uri.parse('${Constants.baseUrl}/schedules')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi lấy danh sách lịch trình: $e");
    }
    return [];
  }

  // Tạo mới lịch trình
  static Future<bool> createSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/schedules'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(scheduleData),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Lỗi tạo lịch trình: $e");
    }
    return false;
  }

  // Xóa lịch trình
  static Future<bool> deleteSchedule(String scheduleId) async {
    try {
      final response = await http.delete(Uri.parse('${Constants.baseUrl}/schedules/$scheduleId')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi xóa lịch trình: $e");
    }
    return false;
  }

  // Bật/tắt trạng thái lịch trình
  static Future<bool> toggleSchedule(String scheduleId) async {
    try {
      final response = await http.put(Uri.parse('${Constants.baseUrl}/schedules/$scheduleId/toggle')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi đổi trạng thái lịch trình: $e");
    }
    return false;
  }
}