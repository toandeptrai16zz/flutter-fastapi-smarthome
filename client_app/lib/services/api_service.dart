import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static final _defaultHeaders = {
    "Bypass-Tunnel-Reminder": "true",
    "ngrok-skip-browser-warning": "true",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  };

  // === DYNAMIC DEVICE REGISTRY ===

  // Lấy toàn bộ danh sách thiết bị từ DB
  static Future<List<Map<String, dynamic>>> getAllDevices() async {
    try {
      final url = '${Constants.baseUrl}/devices';
      print("🚀 DEBUG getAllDevices: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 15));
      print("📥 getAllDevices status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        print("📥 getAllDevices count: ${list.length}");
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      print("❌ Lỗi lấy danh sách thiết bị: $e");
    }
    return [];
  }

  // Tạo thiết bị mới
  static Future<bool> createDevice(Map<String, dynamic> data) async {
    try {
      final url = '${Constants.baseUrl}/devices';
      print("🚀 DEBUG createDevice: $url data=$data");
      final response = await http.post(
        Uri.parse(url),
        headers: {..._defaultHeaders, "Content-Type": "application/json"},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      print("📥 createDevice status: ${response.statusCode} body: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Lỗi tạo thiết bị: $e");
      return false;
    }
  }

  // Xóa thiết bị
  static Future<bool> deleteDevice(String deviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/devices/$deviceId'),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi xóa thiết bị: $e");
      return false;
    }
  }

  // Cập nhật thông tin thiết bị (Đổi tên, phòng, loại)
  static Future<bool> updateDevice(String deviceId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/devices/$deviceId'),
        headers: {..._defaultHeaders, "Content-Type": "application/json"},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi cập nhật thiết bị: $e");
      return false;
    }
  }

  // === CÁC API CŨ ===

  // Gửi lệnh Bật/Tắt
  static Future<bool> toggleDevice(String deviceId, bool status) async {
    try {
      final url = '${Constants.baseUrl}/device/update';
      print("🚀 DEBUG: Calling toggleDevice: $url");
      final response = await http.post(
        Uri.parse(url), 
        headers: {
          "Content-Type": "application/json",
          "Bypass-Tunnel-Reminder": "true",
          "ngrok-skip-browser-warning": "true",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
        body: jsonEncode({
          "device_id": deviceId,
          "status": status
        }),
      ).timeout(const Duration(seconds: 15));
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
      final url = '${Constants.baseUrl}/device/$deviceId';
      print("🚀 DEBUG: Calling getDeviceStatus: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          "ngrok-skip-browser-warning": "true",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
      );
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
      final url = '${Constants.baseUrl}/sensors/latest';
      print("🚀 DEBUG: Calling getLatestSensorData: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          "ngrok-skip-browser-warning": "true",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
      ).timeout(const Duration(seconds: 15));
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
      final url = '${Constants.baseUrl}/schedules';
      print("🚀 DEBUG: Calling getSchedules: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          "ngrok-skip-browser-warning": "true",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
      ).timeout(const Duration(seconds: 15));
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
      final url = '${Constants.baseUrl}/schedules';
      print("🚀 DEBUG: Calling createSchedule: $url");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Bypass-Tunnel-Reminder": "true",
          "ngrok-skip-browser-warning": "true",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
        body: jsonEncode(scheduleData),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Lỗi tạo lịch trình: $e");
    }
    return false;
  }

  // Xóa lịch trình
  static Future<bool> deleteSchedule(String scheduleId) async {
    try {
      final url = '${Constants.baseUrl}/schedules/$scheduleId';
      print("🚀 DEBUG: Calling deleteSchedule: $url");
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Bypass-Tunnel-Reminder": "true",
          "ngrok-skip-browser-warning": "true",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi xóa lịch trình: $e");
    }
    return false;
  }

  // Bật/tắt trạng thái lịch trình
  static Future<bool> toggleSchedule(String scheduleId) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/schedules/$scheduleId/toggle'),
        headers: {"Bypass-Tunnel-Reminder": "true",
          "ngrok-skip-browser-warning": "true"},
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi đổi trạng thái lịch trình: $e");
    }
    return false;
  }

  // --- TRỢ LÝ AI ---
  // Gửi lệnh giọng nói dạng text lên Backend
  static Future<Map<String, dynamic>?> sendVoiceCommand(String text) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/ai/chat'),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "bypass-tunnel-reminder": "true"
        },
        body: jsonEncode({"message": text}),
      ).timeout(const Duration(seconds: 10)); // AI có thể phản hồi chậm 1-2s
      
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Lỗi AI Chat: $e");
    }
    return null;
  }
}