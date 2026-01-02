import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
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
      home: const LoginScreen(),
    );
  }
}