import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  int _selectedThemeIndex = 0;
  int _firstDayOfWeek = 1; // 0=周日, 1=周一, 6=周六
  int _lunarDisplayMode = 0; // 0=节日+农历, 1=仅农历, 2=不显示

  int get selectedThemeIndex => _selectedThemeIndex;
  int get firstDayOfWeek => _firstDayOfWeek;
  int get lunarDisplayMode => _lunarDisplayMode;
  ThemeData get currentTheme => AppThemes.themes[_selectedThemeIndex];
  CalendarThemeConfig get currentConfig => AppThemes.configs[_selectedThemeIndex];

  ThemeProvider({
    int themeIndex = 0,
    int firstDayOfWeek = 1,
    int lunarDisplayMode = 0,
  })  : _selectedThemeIndex = themeIndex,
        _firstDayOfWeek = firstDayOfWeek,
        _lunarDisplayMode = lunarDisplayMode;

  Future<void> setTheme(int index) async {
    if (index < 0 || index >= AppThemes.themes.length) return;
    _selectedThemeIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', index);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    _firstDayOfWeek = day;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('first_day_of_week', day);
  }

  Future<void> setLunarDisplayMode(int mode) async {
    _lunarDisplayMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lunar_display_mode', mode);
  }

  static Future<Map<String, int>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'themeIndex': prefs.getInt('theme_index') ?? 0,
      'firstDayOfWeek': prefs.getInt('first_day_of_week') ?? 1,
      'lunarDisplayMode': prefs.getInt('lunar_display_mode') ?? 0,
    };
  }
}
