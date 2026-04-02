import 'dart:io';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart'; // Thêm Splash Screen
import 'utils/constants.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'smarthome_alerts',
        channelKey: 'alerts_channel',
        channelName: 'SmartHome Alerts',
        channelDescription: 'Thông báo An ninh & AI',
        defaultColor: const Color(0xFF00E5FF),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
      )
    ],
    debug: true
  );
  
  // Bỏ qua kiểm tra chứng chỉ SSL (cực kỳ quan trọng khi dùng Ngrok/Localtunnel)
  HttpOverrides.global = MyHttpOverrides();
  
  await Constants.init();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Smart Home',
      // ✅ Sửa tên darkTheme thành appDarkTheme cho khớp file app_theme.dart
      theme: appDarkTheme, 
      home: const SplashScreen(), // Khởi chạy từ đây
    );
  }
}