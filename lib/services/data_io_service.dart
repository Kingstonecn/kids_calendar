import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/schedule.dart';
import '../db/schedule_dao.dart';
import '../utils/date_utils.dart' as date_utils;

class DataIoService {
  final ScheduleDao _dao = ScheduleDao();

  /// 导出所有日程为 CSV 并分享
  Future<void> exportCsv(BuildContext context) async {
    final schedules = await _dao.getAll();
    if (schedules.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有可导出的日程')),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    // BOM for Excel UTF-8 compatibility
    buffer.write('﻿');
    buffer.writeln('标题,日期,开始时间,结束时间,分类,描述,是否打卡,关联应用');
    for (final s in schedules) {
      final date = s.date;
      final start = s.startTime ?? '';
      final end = s.endTime ?? '';
      final completed = s.isCompleted ? '是' : '否';
      final app = s.appName ?? '';
      // Escape commas and quotes in description
      final desc = _escapeCsv(s.description);
      final title = _escapeCsv(s.title);
      buffer.writeln('$title,$date,$start,$end,${s.category},$desc,$completed,$app');
    }

    await _shareFile(context, buffer.toString(), 'kids_calendar.csv', 'text/csv');
  }

  /// 导出所有日程为 JSON 并分享
  Future<void> exportJson(BuildContext context) async {
    final schedules = await _dao.getAll();
    if (schedules.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有可导出的日程')),
        );
      }
      return;
    }

    final list = schedules.map((s) => s.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(list);

    await _shareFile(context, jsonStr, 'kids_calendar.json', 'application/json');
  }

  /// 从 CSV 文件导入
  /// 返回 (成功数, 失败数)
  Future<({int success, int failed})> importCsv(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return (success: 0, failed: 0);

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    // Remove BOM if present
    final clean = content.replaceFirst('﻿', '');
    final lines = LineSplitter.split(clean).toList();
    if (lines.length < 2) return (success: 0, failed: 0);

    // Skip header line
    final schedules = <Schedule>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = _parseCsvLine(line);
      if (cols.length < 5) continue;

      final title = cols[0].trim();
      final date = cols[1].trim();
      final startTime = cols[2].trim();
      final endTime = cols[3].trim();
      final category = cols[4].trim();
      final description = cols.length > 5 ? cols[5].trim() : '';
      final isCompleted = cols.length > 6 ? cols[6].trim() == '是' : false;

      if (title.isEmpty || !_isValidDate(date)) continue;

      schedules.add(Schedule(
        title: title,
        date: date,
        startTime: startTime.isNotEmpty ? startTime : null,
        endTime: endTime.isNotEmpty ? endTime : null,
        category: category.isNotEmpty ? category : '其他',
        description: description,
        isCompleted: isCompleted,
      ));
    }

    return _importWithDedup(schedules);
  }

  /// 从 JSON 文件导入
  /// 返回 (成功数, 失败数)
  Future<({int success, int failed})> importJson(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return (success: 0, failed: 0);

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final list = jsonDecode(content) as List;

    final schedules = <Schedule>[];
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final title = map['title'] as String? ?? '';
      final date = map['date'] as String? ?? '';
      if (title.isEmpty || !_isValidDate(date)) continue;

      schedules.add(Schedule(
        title: title,
        date: date,
        startTime: map['startTime'] as String?,
        endTime: map['endTime'] as String?,
        category: (map['category'] as String?) ?? '其他',
        description: (map['description'] as String?) ?? '',
        colorIndex: (map['colorIndex'] as int?) ?? 0,
        isRepeating: map['isRepeating'] == true,
        repeatRule: map['repeatRule'] as String?,
        hasAlarm: map['hasAlarm'] == true,
        alarmMinutesBefore: map['alarmMinutesBefore'] as int?,
        isCompleted: map['isCompleted'] == true,
        appPackageName: map['appPackageName'] as String?,
        appName: map['appName'] as String?,
      ));
    }

    return _importWithDedup(schedules);
  }

  /// 去重插入：跳过标题+日期+时间重叠的重复项
  Future<({int success, int failed})> _importWithDedup(List<Schedule> incoming) async {
    if (incoming.isEmpty) return (success: 0, failed: 0);

    // 按日期分组，分批查库
    final byDate = <String, List<Schedule>>{};
    for (final s in incoming) {
      byDate.putIfAbsent(s.date, () => []).add(s);
    }

    int success = 0, failed = 0;
    final toInsert = <Schedule>[];

    for (final date in byDate.keys) {
      final existing = await _dao.getByDate(date);

      for (final s in byDate[date]!) {
        bool isDup = false;

        // 与数据库中已有日程比对
        for (final ext in existing) {
          if (_isDuplicate(ext, s)) {
            isDup = true;
            break;
          }
        }

        // 与本次待插入列表中已确认的其他日程比对
        if (!isDup) {
          for (final acc in toInsert) {
            if (acc.date == s.date && _isDuplicate(acc, s)) {
              isDup = true;
              break;
            }
          }
        }

        if (isDup) {
          failed++;
        } else {
          toInsert.add(s);
          success++;
        }
      }
    }

    if (toInsert.isNotEmpty) {
      await _dao.insertAll(toInsert);
    }
    return (success: success, failed: failed);
  }

  /// 判断两个日程是否重复：同标题 + 同日期 + 时间重叠
  bool _isDuplicate(Schedule a, Schedule b) {
    if (a.title != b.title || a.date != b.date) return false;

    final aStart = a.startTime;
    final aEnd = a.endTime;
    final bStart = b.startTime;
    final bEnd = b.endTime;

    // 双方都无时间 → 全天的重复
    if (aStart == null && bStart == null) return true;
    // 一方有时间一方无 → 也视为重叠
    if (aStart == null || bStart == null) return true;

    // 解析分钟数
    int parseMin(String t) {
      final parts = t.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final aS = parseMin(aStart);
    final aE = aEnd != null ? parseMin(aEnd) : aS + 60;
    final bS = parseMin(bStart);
    final bE = bEnd != null ? parseMin(bEnd) : bS + 60;

    // 标准区间重叠检测
    return aS < bE && bS < aE;
  }

  Future<void> _shareFile(BuildContext context, String content, String filename, String mimeType) async {
    final dir = await Directory.systemTemp.createTemp('kids_calendar_');
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: '亲子时光 - 日程导出 ($filename)',
    );
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }

  bool _isValidDate(String date) {
    try {
      final d = DateTime.tryParse(date);
      return d != null && date.length == 10;
    } catch (_) {
      return false;
    }
  }
}
