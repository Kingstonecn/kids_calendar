import 'package:flutter/material.dart';
import 'constants.dart';

/// 日历组件自定义配置
class CalendarThemeConfig {
  final double containerRadius;
  final double cellRadius;
  final bool showLunar;
  final double barRadius;
  final double barFontSize;
  final bool useCompactDate;

  const CalendarThemeConfig({
    required this.containerRadius,
    required this.cellRadius,
    required this.showLunar,
    required this.barRadius,
    required this.barFontSize,
    required this.useCompactDate,
  });
}

/// 4 套主题定义
class AppThemes {
  AppThemes._();

  static const List<CalendarThemeConfig> configs = [
    CalendarThemeConfig(
      containerRadius: 16, cellRadius: 6, showLunar: true,
      barRadius: 2, barFontSize: 7, useCompactDate: false,
    ),
    CalendarThemeConfig(
      containerRadius: 24, cellRadius: 12, showLunar: true,
      barRadius: 8, barFontSize: 7, useCompactDate: false,
    ),
    CalendarThemeConfig(
      containerRadius: 0, cellRadius: 0, showLunar: false,
      barRadius: 1, barFontSize: 6, useCompactDate: true,
    ),
    CalendarThemeConfig(
      containerRadius: 20, cellRadius: 8, showLunar: true,
      barRadius: 4, barFontSize: 7, useCompactDate: false,
    ),
  ];

  static final List<ThemeData> themes = [
    _defaultTheme,
    _warmRoundedTheme,
    _minimalTheme,
    _glassmorphismTheme,
  ];

  static const List<ThemeInfo> infos = [
    ThemeInfo('蓝色清爽', '蓝色清爽，标准圆角', Icons.light_mode, [
      Color(0xFF5B8DEF), Color(0xFFF8F9FA), Color(0xFFFF6B6B),
    ]),
    ThemeInfo('暖萌圆润', '暖杏色珊瑚橙，大圆角', Icons.favorite, [
      Color(0xFFFF8A65), Color(0xFFFFF3E0), Color(0xFFCE93D8),
    ]),
    ThemeInfo('极简留白', '黑白杂志风，克制留白', Icons.dark_mode, [
      Color(0xFF2C3E50), Color(0xFFFFFFFF), Color(0xFFD4A574),
    ]),
    ThemeInfo('渐变通透', '渐变背景，通透质感', Icons.blur_on, [
      Color(0xFF7E57C2), Color(0xFFF5F0FF), Color(0xFF80CBC4),
    ]),
  ];

  // ===== 各主题 ThemeData =====

  // --- 0: 默认 (同当前样式) ---
  static final ThemeData _defaultTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppConstants.backgroundColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true, elevation: 0,
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppConstants.primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // --- 1: 暖萌圆润 ---
  static final ThemeData _warmRoundedTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8A65),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF3E0),
    appBarTheme: const AppBarTheme(
      centerTitle: true, elevation: 0,
      backgroundColor: Color(0xFFFF8A65),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFFF8A65),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFFFF8A65),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // --- 2: 极简留白 ---
  static final ThemeData _minimalTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2C3E50),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      centerTitle: true, elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A1A),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF2C3E50),
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2C3E50),
      unselectedItemColor: Color(0xFFBDC3C7),
      type: BottomNavigationBarType.fixed, elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFECF0F1), thickness: 0.5,
    ),
  );

  // --- 3: 毛玻璃 ---
  static final ThemeData _glassmorphismTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7E57C2),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F0FF),
    appBarTheme: const AppBarTheme(
      centerTitle: true, elevation: 0,
      backgroundColor: Color(0xFF7E57C2),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF7E57C2),
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      color: Colors.white.withOpacity(0.75),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: const Color(0xFF7E57C2),
      unselectedItemColor: const Color(0xFFB39DDB),
      type: BottomNavigationBarType.fixed, elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.8),
    ),
  );
}

class ThemeInfo {
  final String name;
  final String description;
  final IconData icon;
  final List<Color> swatches;

  const ThemeInfo(this.name, this.description, this.icon, this.swatches);
}
