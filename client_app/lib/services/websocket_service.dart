import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

/// Singleton WebSocket service - push realtime từ Backend → Flutter
/// Thay thế hoàn toàn việc dùng Timer.periodic HTTP polling
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _disposed = false;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  /// Lấy WS URL từ baseUrl (http → ws)
  String get _wsUrl {
    final base = Constants.baseUrl.replaceFirst('http', 'ws');
    return '$base/ws';
  }

  /// Kết nối tới WebSocket Backend
  void connect() {
    if (_isConnected || _disposed) return;
    try {
      final wsUrl = _wsUrl;
      final uri = Uri.parse(wsUrl);
      print('🔌 WebSocket Attempting: [${uri.toString()}] (Path: ${uri.path})');
      
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      print('🔌 WebSocket connected to $wsUrl');

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            if (json['type'] != 'pong') {
              // Không forward ping-pong vào stream UI
              _controller.add(json);
            }
          } catch (e) {
            print('❌ Lỗi parse WebSocket data: $e');
          }
        },
        onDone: () {
          print('🔌 WebSocket disconnected');
          _isConnected = false;
          _scheduleReconnect();
        },
        onError: (e) {
          print('❌ WebSocket error: $e');
          _isConnected = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      // Gửi ping mỗi 20s để giữ kết nối sống
      Timer.periodic(const Duration(seconds: 20), (t) {
        if (_disposed || !_isConnected) {
          t.cancel();
          return;
        }
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      });
    } catch (e) {
      print('❌ Không thể kết nối WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Tự động thử kết nối lại sau 3 giây nếu bị ngắt
  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_disposed) return;
      try {
        print('🔄 Thử kết nối lại WebSocket...');
        _channel?.sink.close();
        _channel = null;
        _isConnected = false;
        connect();
      } catch (e) {
        print('❌ Lỗi khi reconnect WebSocket: $e');
        _scheduleReconnect(); // tiếp tục thử
      }
    });
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
