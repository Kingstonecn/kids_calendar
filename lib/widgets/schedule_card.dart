import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/constants.dart';
import '../screens/schedule_form_screen.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.onLongPress,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.getCategoryColorByName(schedule.category);
    final timeRange = date_utils.DateUtils.formatTimeRange(
      schedule.startTime,
      schedule.endTime,
    );
    final isPast = _isPastDate(schedule.date);

    return Opacity(
      opacity: isPast ? 0.65 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleFormScreen(schedule: schedule),
              ),
            );
          },
          onLongPress: onLongPress,
          onDoubleTap: onDoubleTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 左侧颜色条
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // 时间列
                if (timeRange.isNotEmpty)
                  SizedBox(
                    width: 65,
                    child: Text(
                      timeRange,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                if (timeRange.isNotEmpty) const SizedBox(width: 12),
                // 内容列
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.truncateTitle(schedule.title),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (schedule.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            schedule.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // 分类标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    schedule.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                    ),
                  ),
                ),
                // 提醒图标
                if (schedule.hasAlarm)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.notifications_none,
                      size: 16,
                      color: AppConstants.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isPastDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }
}
