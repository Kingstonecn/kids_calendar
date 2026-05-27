import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_apps/device_apps.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../screens/schedule_form_screen.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as date_utils;


class DayView extends StatelessWidget {
  const DayView({super.key});

  static const _hourHeight = 70.0;
  static const _startHour = 0;
  static const _hourCount = 24;

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
            _buildWeekStrip(date, provider),
            const Divider(height: 1),
            Expanded(child: _buildTimeline(schedules, date, provider, context)),
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

  Widget _buildWeekStrip(DateTime selectedDate, ScheduleProvider provider) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = selectedDate.weekday;
    final monday = selectedDate.subtract(Duration(days: weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: List.generate(7, (i) {
          final date = monday.add(Duration(days: i));
          final isSelected =
              date_utils.DateUtils.isSameDay(date, selectedDate);
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.selectDate(date),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryColor : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      weekdays[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeline(List<Schedule> schedules, DateTime date, ScheduleProvider provider, BuildContext context) {
    final timed = schedules.where((s) => s.startTime != null).toList();
    final totalHeight = _hourCount * _hourHeight;

    return SingleChildScrollView(
      controller: ScrollController(initialScrollOffset: 9 * _hourHeight),
      child: Column(
        children: [
          SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // 点击空白处创建日程
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) {
                      final tapY = details.localPosition.dy;
                      final hour = (tapY / _hourHeight).floor().clamp(0, 23);
                      final minute = ((tapY % _hourHeight) / _hourHeight * 60).round().clamp(0, 59);
                      _createScheduleAt(context, date, hour, minute);
                    },
                  ),
                ),
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

  void _createScheduleAt(BuildContext context, DateTime date, int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          initialDate: date,
          initialTime: time,
        ),
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


  Widget _buildScheduleBlock(Schedule schedule, BuildContext context) {
    final parsed = date_utils.DateUtils.parseTimeOfDay(schedule.startTime!);
    if (parsed == null) return const SizedBox.shrink();
    final (hour, minute) = parsed;
    final top = (hour - _startHour) * _hourHeight + minute / 60 * _hourHeight;

    double durationHours = 1.0;
    if (schedule.endTime != null) {
      final eParsed = date_utils.DateUtils.parseTimeOfDay(schedule.endTime!);
      if (eParsed != null) {
        final (eh, em) = eParsed;
        durationHours = (eh - hour) + (em - minute) / 60;
      }
    }
    final height = durationHours * _hourHeight;

    final color = AppConstants.getCategoryColorByName(schedule.category);

    return Positioned(
      top: top,
      left: 52,
      right: 8,
      height: height.clamp(20, _hourHeight * 6),
      child: GestureDetector(
        onTap: () => _openSchedule(context, schedule),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      schedule.title,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      schedule.startTime!,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (schedule.appPackageName != null)
                _buildAppIcon(
                  context,
                  schedule.appPackageName!,
                  schedule.appName,
                  size: 30,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 关联 App 图标按钮
  Widget _buildAppIcon(BuildContext context, String packageName, String? appName, {double size = 18}) {
    return _AppIconWidget(
      packageName: packageName,
      appName: appName,
      size: size,
    );
  }
}

/// 独立 StatefulWidget：异步加载 App 图标，避免在 build 阶段触发平台通道
class _AppIconWidget extends StatefulWidget {
  final String packageName;
  final String? appName;
  final double size;

  const _AppIconWidget({
    required this.packageName,
    this.appName,
    this.size = 18,
  });

  @override
  State<_AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<_AppIconWidget> {
  Uint8List? _iconData;
  static final Map<String, Uint8List?> _cache = {};

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final pkg = widget.packageName;
    if (pkg.isEmpty) return;

    // 缓存命中
    if (_cache.containsKey(pkg)) {
      if (mounted) setState(() => _iconData = _cache[pkg]);
      return;
    }

    // 异步加载
    try {
      final app = await DeviceApps.getApp(pkg, true);
      if (app is ApplicationWithIcon) {
        _cache[pkg] = app.icon;
        if (mounted) setState(() => _iconData = app.icon);
      } else {
        _cache[pkg] = null;
        if (mounted) setState(() => _iconData = null);
      }
    } catch (_) {
      _cache[pkg] = null;
      if (mounted) setState(() => _iconData = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => DayView._launchApp(context, widget.packageName),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Tooltip(
          message: widget.appName ?? widget.packageName,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade100,
            ),
            child: _iconData != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      _iconData!,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.open_in_new, size: widget.size - 4, color: Colors.grey),
                    ),
                  )
                : Icon(Icons.open_in_new,
                    size: widget.size - 4, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
