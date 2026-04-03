import 'dart:io';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bỏ qua kiểm tra chứng chỉ SSL (quan trọng khi dùng Ngrok/Localtunnel)
  HttpOverrides.global = MyHttpOverrides();

  // ✅ BẮT BUỘC: Khởi tạo AwesomeNotifications trước khi dùng
  await AwesomeNotifications().initialize(
    null, // null = dùng icon mặc định của app
    [
      NotificationChannel(
        channelKey: 'alerts_channel',
        channelName: 'AI Security Alerts',
        channelDescription: 'Thông báo cảnh báo an ninh từ AI',
        defaultColor: AppColors.primary,
        ledColor: AppColors.primary,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Thông báo cơ bản từ SmartHome',
        defaultColor: AppColors.primary,
        importance: NotificationImportance.Default,
      ),
    ],
    debug: false,
  );

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
      theme: appDarkTheme,
      home: const LoginScreen(),
    );
  }
}
