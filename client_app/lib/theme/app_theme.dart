import 'package:flutter/material.dart';

// 1. BẢNG MÀU TĨNH
class AppColors {
  static const Color primary = Color(0xFF137FEC); 

  // Dark Mode
  static const Color backgroundDark = Color(0xFF101922); 
  static const Color surfaceDark = Color(0xFF1B2531);    
  static const Color textMainDark = Colors.white;
  static const Color textSubDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);
  static const Color iconDark = Colors.white;

  // Light Mode
  static const Color backgroundLight = Color(0xFFF6F7F8); 
  static const Color surfaceLight = Colors.white;         
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textSubLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color iconLight = Color(0xFF64748B);

  // MÀU QUAN TRỌNG (Đã thêm lại để không lỗi LoginScreen)
  static const Color textSecondary = Color(0xFF94A3B8); 

  static const Color active = Color(0xFF4ADE80); 
  static const Color offline = Color(0xFFEF4444); 
  static const Color warning = Color(0xFFF59E0B); 
}

// 2. CLASS QUẢN LÝ THEME ĐỘNG
class AppThemeColors {
  final bool isDark;
  
  AppThemeColors(this.isDark);

  Color get background => isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get textMain => isDark ? AppColors.textMainDark : AppColors.textMainLight;
  Color get textSub => isDark ? AppColors.textSubDark : AppColors.textSubLight;
  Color get border => isDark ? AppColors.borderDark : AppColors.borderLight;
  
  // ✅ Đã thêm getter icon để không lỗi Dashboard
  Color get icon => isDark ? AppColors.iconDark : AppColors.iconLight; 
  
  Color get primary => AppColors.primary;
}

// 3. CẤU HÌNH THEME DATA (Đây là cái biến main.dart đang tìm kiếm)
final ThemeData appDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  primaryColor: AppColors.primary,
  fontFamily: 'Roboto', 
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    surface: AppColors.surfaceDark,
    background: AppColors.backgroundDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: Colors.white),
  ),
);