class RepeatRule {
  final String type; // 'daily', 'weekly', 'monthly', 'yearly'
  final int interval;
  final List<int>? weekdays; // 仅 weekly 类型: 1=周一 ... 7=周日
  final String? endDate; // 'yyyy-MM-dd', null=永不结束

  RepeatRule({
    required this.type,
    this.interval = 1,
    this.weekdays,
    this.endDate,
  });

  String toJson() {
    final map = <String, dynamic>{
      'type': type,
      'interval': interval,
    };
    if (weekdays != null) map['weekdays'] = weekdays;
    if (endDate != null) map['endDate'] = endDate;
    return map.toString(); // 存为简易 JSON
  }

  static RepeatRule? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      // 简易解析: {type: daily, interval: 1, weekdays: [1,3,5], endDate: 2026-12-31}
      final type = _extractValue(json, 'type') ?? 'daily';
      final interval = int.tryParse(_extractValue(json, 'interval') ?? '1') ?? 1;
      final endDate = _extractValue(json, 'endDate');

      List<int>? weekdays;
      final wdMatch = RegExp(r'weekdays:\s*\[([^\]]*)\]').firstMatch(json);
      if (wdMatch != null) {
        weekdays = wdMatch.group(1)!
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList();
      }

      return RepeatRule(
        type: type,
        interval: interval,
        weekdays: weekdays,
        endDate: endDate,
      );
    } catch (_) {
      return null;
    }
  }

  static String _extractValue(String json, String key) {
    final reg = RegExp('$key:\\s*([^,}\\[\\]]+)');
    final match = reg.firstMatch(json);
    return match?.group(1)?.trim() ?? '';
  }

  /// 检查某个日期是否匹配此重复规则
  bool matches(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;

    // 检查是否超出结束日期
    if (endDate != null) {
      final end = DateTime.tryParse(endDate!);
      if (end != null && date.isAfter(end)) return false;
    }

    // 需要知道原始日程日期来计算间隔
    return true; // 由上层逻辑处理
  }
}
