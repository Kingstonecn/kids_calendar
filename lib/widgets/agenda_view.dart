import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as date_utils;

class AgendaView extends StatelessWidget {
  const AgendaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedules = provider.agendaSchedules;

        if (schedules.isEmpty && !provider.isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_note, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  '暂无日程',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // 按日期分组
        final Map<String, List<Schedule>> grouped = {};
        for (final s in schedules) {
          grouped.putIfAbsent(s.date, () => []).add(s);
        }

        // 生成本天起前后各一年的所有日期
        final today = DateTime.now();
        final start = DateTime(today.year - 1, today.month, today.day);
        final dayCount = DateTime(today.year + 1, today.month, today.day)
            .difference(start)
            .inDays;
        final allDates = List.generate(dayCount + 1, (i) => start.add(Duration(days: i)));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: allDates.length,
          itemBuilder: (context, index) {
            final date = allDates[index];
            final dateStr = date_utils.DateUtils.formatDate(date);
            final daySchedules = grouped[dateStr] ?? [];
            return _buildDateGroup(context, dateStr, daySchedules);
          },
        );
      },
    );
  }

  Widget _buildDateGroup(BuildContext context, String dateStr, List<Schedule> schedules) {
    final date = DateTime.tryParse(dateStr);
    final isToday = date != null && date_utils.DateUtils.isSameDay(date, DateTime.now());
    final isEmpty = schedules.isEmpty;

    // 格式化日期头
    String header;
    if (date != null) {
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final wd = weekdays[date.weekday - 1];
      if (isToday) {
        header = '今天  $wd';
      } else {
        header = '${date.month}月${date.day}日  $wd';
      }
    } else {
      header = dateStr;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期分隔头
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: isToday
              ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
              : Colors.grey.shade50,
          child: Row(
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '今天',
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              Text(
                header,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                  color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                ),
              ),
              if (!isEmpty) ...[
                const Spacer(),
                Text(
                  '${schedules.length}个日程',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        // 日程卡片或空状态
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.event_busy, size: 14, color: Colors.grey.shade300),
                const SizedBox(width: 6),
                Text(
                  '没有日程',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                ),
              ],
            ),
          )
        else
          ...schedules.map((s) => _buildScheduleItem(s)),
      ],
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    final color = AppConstants.getCategoryColorByName(schedule.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              // 时间列
              SizedBox(
                width: 42,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.startTime ?? '全天',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (schedule.endTime != null)
                      Text(
                        schedule.endTime!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              // 色条
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题和分类
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.truncateTitle(schedule.title),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        schedule.category,
                        style: TextStyle(fontSize: 9, color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
