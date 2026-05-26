import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// 日期格式化
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// 时间格式化
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// 获取今日日期字符串
  static String today() => formatDate(DateTime.now());

  /// 解析日期字符串
  static DateTime? parseDate(String dateStr) => DateTime.tryParse(dateStr);

  /// 获取中文友好日期显示
  static String friendlyDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == -1) return '昨天';
    if (diff > 0 && diff <= 6) {
      return _weekdayName(date.weekday);
    }
    if (diff < 0 && diff >= -6) {
      return '上周${_weekdayName(date.weekday)}';
    }
    return '${date.month}月${date.day}日';
  }

  /// 获取详细日期显示
  static String detailDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final friendly = friendlyDate(dateStr);
    if (friendly == '今天' || friendly == '明天' || friendly == '昨天') {
      return '$friendly ${date.month}月${date.day}日';
    }
    return '${date.year}年${date.month}月${date.day}日 $friendly';
  }

  static String _weekdayName(int weekday) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[(weekday - 1) % 7];
  }

  /// 获取当前月份的日期网格 (包含上月末尾和下月开头补齐)
  static List<DateTime?> getMonthGrid(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 周日=0
    final daysInMonth = lastDay.day;

    final grid = <DateTime?>[];
    // 上个月补齐
    for (int i = 0; i < startWeekday; i++) {
      final prevDay = DateTime(year, month, 1 - startWeekday + i);
      grid.add(prevDay);
    }
    // 本月
    for (int d = 1; d <= daysInMonth; d++) {
      grid.add(DateTime(year, month, d));
    }
    // 下个月补齐 (填满6行)
    while (grid.length < 42) {
      final nextDay = DateTime(year, month, daysInMonth + (grid.length - startWeekday - daysInMonth + 1));
      grid.add(nextDay);
    }
    return grid;
  }

  /// 检查两个日期是否为同一天
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 格式化时间范围
  static String formatTimeRange(String? startTime, String? endTime) {
    if (startTime == null && endTime == null) return '';
    if (startTime != null && endTime != null) return '$startTime - $endTime';
    return startTime ?? endTime ?? '';
  }

  /// 解析时间字符串，支持 "HH:mm" 和中文格式（"上午H:mm" / "下午H:mm"）
  /// 返回 (hour, minute)，解析失败返回 null
  static (int hour, int minute)? parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;

    var hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (minute == null) return null;

    if (hour != null && hour >= 0 && hour < 24) {
      return (hour, minute);
    }

    // 中文格式：上午/下午 + 数字
    if (parts[0].startsWith('上午')) {
      hour = int.tryParse(parts[0].substring(2));
      if (hour == null) return null;
      return (hour == 12 ? 0 : hour, minute);
    } else if (parts[0].startsWith('下午')) {
      hour = int.tryParse(parts[0].substring(2));
      if (hour == null) return null;
      return (hour == 12 ? 12 : hour + 12, minute);
    }

    return null;
  }
}
