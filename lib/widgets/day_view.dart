import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_apps/device_apps.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../screens/schedule_form_screen.dart';
import '../utils/constants.dart';


class DayView extends StatelessWidget {
  const DayView({super.key});

  static const _hourHeight = 70.0;
  static const _startHour = 0;
  static const _hourCount = 24;
  static final Map<String, Uint8List?> _appIconCache = {};

  /// 获取 App 图标（缓存+懒加载）
  static Future<Uint8List?> _getAppIcon(String packageName) async {
    if (_appIconCache.containsKey(packageName)) {
      return _appIconCache[packageName];
    }
    try {
      final app = await DeviceApps.getApp(packageName, true);
      if (app is ApplicationWithIcon) {
        _appIconCache[packageName] = app.icon;
        return app.icon;
      }
    } catch (_) {}
    _appIconCache[packageName] = null; // 缓存失败结果
    return null;
  }

  /// 启动关联 App
  static Future<void> _launchApp(BuildContext context, String packageName) async {
    try {
      final launched = await DeviceApps.openApp(packageName);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到关联应用')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法启动关联应用')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedules = provider.currentSchedules;
        final date = provider.selectedDate;

        return Column(
          children: [
            _buildDateHeader(date),
            const Divider(height: 1),
            Expanded(child: _buildTimeline(schedules, context)),
          ],
        );
      },
    );
  }

  void _openSchedule(BuildContext context, Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(schedule: schedule),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final label = '${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      width: double.infinity,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimeline(List<Schedule> schedules, BuildContext context) {
    final allDay = schedules.where((s) => s.startTime == null).toList();
    final timed = schedules.where((s) => s.startTime != null).toList();
    final totalHeight = _hourCount * _hourHeight;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (allDay.isNotEmpty)
            ...allDay.map((s) => _allDayTile(s, context)),
          SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // 小时格线
                ...List.generate(_hourCount, (i) => _buildHourLine(i)),
                // 当前时间指示线
                _buildNowLine(),
                // 日程块
                ...timed.map((s) => _buildScheduleBlock(s, context)),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHourLine(int hour) {
    return Positioned(
      top: hour * _hourHeight,
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: _hourHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: _hourHeight,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowLine() {
    final now = DateTime.now();
    final totalMinutes = now.hour * 60 + now.minute;
    final top = totalMinutes / 60 * _hourHeight;
    return Positioned(
      top: top,
      left: 44,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 1.5, color: Colors.red),
          ),
        ],
      ),
    );
  }

  /// 全天事件
  Widget _allDayTile(Schedule schedule, BuildContext context) {
    final color = AppConstants.getCategoryColorByName(schedule.category);
    return GestureDetector(
      onTap: () => _openSchedule(context, schedule),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border(left: BorderSide(color: color, width: 3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Text('📅 ', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(schedule.title,
                  style: const TextStyle(fontSize: 12)),
            ),
            if (schedule.appPackageName != null)
              _buildAppIcon(
                context,
                schedule.appPackageName!,
                schedule.appName,
              ),
            const SizedBox(width: 4),
            const Text('全天',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleBlock(Schedule schedule, BuildContext context) {
    final parts = schedule.startTime!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final top = (hour - _startHour) * _hourHeight + minute / 60 * _hourHeight;

    double durationHours = 1.0;
    if (schedule.endTime != null) {
      final eParts = schedule.endTime!.split(':');
      final eh = int.parse(eParts[0]);
      final em = int.parse(eParts[1]);
      durationHours = (eh - hour) + (em - minute) / 60;
    }
    final height = durationHours * _hourHeight;

    final color = AppConstants.getCategoryColorByName(schedule.category);

    return Positioned(
      top: top,
      left: 52,
      right: 8,
      height: height.clamp(36, _hourHeight * 6),
      child: GestureDetector(
        onTap: () => _openSchedule(context, schedule),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      schedule.title,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (schedule.appPackageName != null)
                    _buildAppIcon(
                      context,
                      schedule.appPackageName!,
                      schedule.appName,
                    ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                schedule.startTime!,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 关联 App 图标按钮
  Widget _buildAppIcon(BuildContext context, String packageName, String? appName) {
    return FutureBuilder<Uint8List?>(
      future: _getAppIcon(packageName),
      builder: (context, snapshot) {
        final iconData = snapshot.data;
        return GestureDetector(
          onTap: () => _launchApp(context, packageName),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Tooltip(
              message: appName ?? packageName,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade100,
                ),
                child: iconData != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          iconData,
                          width: 18,
                          height: 18,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.open_in_new, size: 14, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.open_in_new,
                        size: 14, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }
}
