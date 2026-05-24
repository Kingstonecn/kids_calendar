import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/constants.dart';
import 'schedule_card.dart';

class TimelineList extends StatelessWidget {
  final List<Schedule> schedules;
  final DateTime selectedDate;

  const TimelineList({
    super.key,
    required this.schedules,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return _buildEmptyState();
    }

    final sorted = List<Schedule>.from(schedules)
      ..sort((a, b) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final schedule = sorted[index];
        return ScheduleCard(
          schedule: schedule,
          onLongPress: () => _jumpToDate(context, schedule),
          onDoubleTap: () => _openForEdit(context, schedule),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final friendly = date_utils.DateUtils.friendlyDate(
      date_utils.DateUtils.formatDate(selectedDate),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: AppConstants.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              '$friendly没有日程哦～',
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 长按跳转到日程对应日期
  void _jumpToDate(BuildContext context, Schedule schedule) {
    final date = DateTime.tryParse(schedule.date);
    if (date != null) {
      context.read<ScheduleProvider>().selectDate(date);
    }
  }

  /// 双击打开编辑
  void _openForEdit(BuildContext context, Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('编辑日程')),
          body: const Center(child: Text('编辑页面')),
        ),
      ),
    );
  }
}
