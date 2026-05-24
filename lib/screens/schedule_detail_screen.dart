import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/schedule_dao.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/constants.dart';
import 'schedule_form_screen.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final int scheduleId;

  const ScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final ScheduleDao _dao = ScheduleDao();
  Schedule? _schedule;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final schedule = await _dao.getById(widget.scheduleId);
    if (mounted) {
      setState(() {
        _schedule = schedule;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日程详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schedule == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: AppConstants.textSecondary),
                      SizedBox(height: 16),
                      Text('未找到该日程',
                          style: TextStyle(color: AppConstants.textSecondary)),
                    ],
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final schedule = _schedule!;
    final color = AppConstants.getCategoryColorByName(schedule.category);
    final timeRange = date_utils.DateUtils.formatTimeRange(
      schedule.startTime,
      schedule.endTime,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 + 分类
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  schedule.category,
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 日期
          _infoRow(
            Icons.calendar_today,
            date_utils.DateUtils.detailDate(schedule.date),
          ),
          if (timeRange.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow(Icons.access_time, timeRange),
          ],

          // 描述
          if (schedule.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '描述',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              schedule.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],

          const Spacer(),

          // 状态信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoSmall('创建时间', schedule.createdAt),
                const SizedBox(height: 4),
                _infoSmall('更新时间', schedule.updatedAt),
                if (schedule.sourceId != null) ...[
                  const SizedBox(height: 4),
                  _infoSmall('来源日程', '#${schedule.sourceId}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleFormScreen(schedule: schedule),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteSchedule(context, schedule),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('删除',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _infoSmall(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 12, color: AppConstants.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12, color: AppConstants.textSecondary),
          ),
        ),
      ],
    );
  }

  _deleteSchedule(BuildContext context, Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个日程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<ScheduleProvider>().deleteSchedule(schedule.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
