import 'package:flutter/material.dart';

/// 日程分类常量
class AppConstants {
  static const String appName = '亲子时光';
  static const String appNameEn = 'Kids Calendar';

  // 日程分类
  static const List<String> categories = [
    '亲子',
    '学习',
    '娱乐',
    '健康',
    '生日',
    '纪念日',
    '运动',
    '其他',
  ];

  // 分类对应颜色
  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B), // 亲子 - 红
    Color(0xFF4ECDC4), // 学习 - 青
    Color(0xFFFFE66D), // 娱乐 - 黄
    Color(0xFF95E1D3), // 健康 - 薄荷
    Color(0xFFF38181), // 生日 - 珊瑚
    Color(0xFFAA96DA), // 纪念日 - 紫
    Color(0xFF6BCB77), // 运动 - 绿
    Color(0xFFB8B8B8), // 其他 - 灰
  ];

  /// 获取分类颜色
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  /// 根据分类名获取颜色
  static Color getCategoryColorByName(String category) {
    final idx = categories.indexOf(category);
    return idx >= 0 ? categoryColors[idx] : categoryColors.last;
  }

  /// 提前提醒选项(分钟)
  static const List<Map<String, dynamic>> alarmOptions = [
    {'label': '准时', 'value': 0},
    {'label': '提前5分钟', 'value': 5},
    {'label': '提前15分钟', 'value': 15},
    {'label': '提前30分钟', 'value': 30},
    {'label': '提前1小时', 'value': 60},
    {'label': '提前1天', 'value': 1440},
  ];

  /// 应用主题色
  static const Color primaryColor = Color(0xFF5B8DEF);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color dividerColor = Color(0xFFE8E8E8);

  /// 日程颜色列表(8种)
  static const List<Color> scheduleColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFF38181),
    Color(0xFFAA96DA),
    Color(0xFF6BCB77),
    Color(0xFFB8B8B8),
  ];

  /// 截断字符串, 使其视觉宽度不超过指定中文字数
  /// 中文字/全角字符算 2, 英文字母算 1, 确保中英文视觉一致
  static String truncateTitle(String text, [int maxCnChars = 18]) {
    final maxWidth = maxCnChars * 2;
    int width = 0;
    for (int i = 0; i < text.length; i++) {
      final cp = text.codeUnitAt(i);
      final isWide = cp >= 0x2E80 && cp <= 0x9FFF; // CJK 及全角
      width += isWide ? 2 : 1;
      if (width > maxWidth) {
        return '${text.substring(0, i)}...';
      }
    }
    return text;
  }
}
