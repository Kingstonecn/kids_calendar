import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../services/notification_service.dart';
import '../widgets/category_picker.dart';
import '../widgets/mini_calendar_dialog.dart';
import '../utils/constants.dart';

class ScheduleFormScreen extends StatefulWidget {
  final Schedule? schedule; // null = 新增, non-null = 编辑

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;
  late String _category;
  late int _colorIndex;
  late bool _hasAlarm;
  late int? _alarmMinutesBefore;
  bool _isEditing = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('yyyy年MM月dd日');

  @override
  void initState() {
    super.initState();
    _isEditing = widget.schedule != null;
    final schedule = widget.schedule;

    _titleController = TextEditingController(text: schedule?.title ?? '');
    _descController = TextEditingController(text: schedule?.description ?? '');
    _selectedDate = schedule != null
        ? DateTime.tryParse(schedule.date) ?? DateTime.now()
        : DateTime.now();
    _startTime = schedule?.startTime != null
        ? _parseTime(schedule!.startTime!)
        : null;
    _endTime = schedule?.endTime != null
        ? _parseTime(schedule!.endTime!)
        : null;
    _category = schedule?.category ?? '亲子';
    _colorIndex = schedule?.colorIndex ?? 0;
    _hasAlarm = schedule?.hasAlarm ?? false;
    _alarmMinutesBefore = schedule?.alarmMinutesBefore ?? 15;
  }

  TimeOfDay? _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑日程' : '新增日程'),
        actions: [
          // 删除按钮（编辑模式）
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          // 复制按钮
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: '复制到其他日期',
            onPressed: _showCopyDialog,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '日程标题 *',
                  hintText: '输入日程标题',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '标题不能为空' : null,
              ),
              const SizedBox(height: 16),

              // 描述
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '输入日程描述（可选）',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 日期
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('日期'),
                subtitle: Text(_displayDateFormat.format(_selectedDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickDate,
              ),
              const Divider(),

              // 开始时间
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('开始时间'),
                subtitle: Text(_startTime != null
                    ? _startTime!.format(context)
                    : '不限'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _pickTime(true),
              ),
              const Divider(),

              // 结束时间
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_off),
                title: const Text('结束时间'),
                subtitle: Text(_endTime != null
                    ? _endTime!.format(context)
                    : '不限'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _pickTime(false),
              ),
              const Divider(),

              // 分类
              const Text('分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CategoryPicker(
                selectedCategory: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const Divider(),

              // 提醒
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开启提醒'),
                subtitle: _hasAlarm && _alarmMinutesBefore != null
                    ? Text('提前 $_alarmMinutesBefore 分钟')
                    : null,
                value: _hasAlarm,
                onChanged: (v) => setState(() => _hasAlarm = v),
              ),
              if (_hasAlarm) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppConstants.alarmOptions.map((opt) {
                    final isSelected =
                        _alarmMinutesBefore == opt['value'] as int;
                    return ChoiceChip(
                      label: Text(opt['label'] as String),
                      selected: isSelected,
                      onSelected: (_) => setState(
                          () => _alarmMinutesBefore = opt['value'] as int),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? '保存修改' : '创建日程',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('zh'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? TimeOfDay(hour: 10, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // 校验结束时间不能早于开始时间
    if (_startTime != null && _endTime != null) {
      final start = _startTime!.hour * 60 + _startTime!.minute;
      final end = _endTime!.hour * 60 + _endTime!.minute;
      if (end <= start) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('结束时间必须晚于开始时间')),
        );
        return;
      }
    }

    final schedule = Schedule(
      id: widget.schedule?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      date: _dateFormat.format(_selectedDate),
      startTime: _startTime?.format(context),
      endTime: _endTime?.format(context),
      category: _category,
      colorIndex: _colorIndex,
      hasAlarm: _hasAlarm,
      alarmMinutesBefore: _hasAlarm ? _alarmMinutesBefore : null,
      isRepeating: widget.schedule?.isRepeating ?? false,
      repeatRule: widget.schedule?.repeatRule,
      sourceId: widget.schedule?.sourceId,
      isCompleted: widget.schedule?.isCompleted ?? false,
      createdAt: widget.schedule?.createdAt,
    );

    final provider = context.read<ScheduleProvider>();

    if (_isEditing) {
      await provider.updateSchedule(schedule);
    } else {
      final id = await provider.addSchedule(schedule);
      schedule.id = id;
    }

    // 处理闹钟
    if (_hasAlarm && schedule.id != null) {
      final alarmDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime?.hour ?? 9,
        _startTime?.minute ?? 0,
      );
      await NotificationService().scheduleNotification(
        scheduleId: schedule.id!,
        title: '日程提醒: ${schedule.title}',
        body: schedule.description.isNotEmpty
            ? schedule.description
            : '您有一个日程即将开始',
        scheduledDate: alarmDate,
        minutesBefore: _alarmMinutesBefore ?? 0,
      );
    } else if (widget.schedule?.id != null) {
      await NotificationService().cancelNotification(widget.schedule!.id!);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个日程吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.schedule?.id != null) {
      await context
          .read<ScheduleProvider>()
          .deleteSchedule(widget.schedule!.id!);

      // 取消通知
      await NotificationService().cancelNotification(widget.schedule!.id!);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  /// 打开复制弹窗 — 核心连续复制功能
  Future<void> _showCopyDialog() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写日程标题')),
      );
      return;
    }

    final result = await showDialog<List<DateTime>>(
      context: context,
      builder: (ctx) => MiniCalendarDialog(
        sourceDate: _selectedDate,
        repeatEndDate: null, // 可根据需要设置
      ),
    );

    if (result != null && result.isNotEmpty) {
      // 先保存当前日程
      if (!_formKey.currentState!.validate()) return;

      final schedule = Schedule(
        id: widget.schedule?.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: _dateFormat.format(_selectedDate),
        startTime: _startTime?.format(context),
        endTime: _endTime?.format(context),
        category: _category,
        colorIndex: _colorIndex,
        hasAlarm: _hasAlarm,
        alarmMinutesBefore: _hasAlarm ? _alarmMinutesBefore : null,
        isCompleted: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      int sourceId;
      if (_isEditing && widget.schedule?.id != null) {
        await context.read<ScheduleProvider>().updateSchedule(schedule);
        sourceId = widget.schedule!.id!;
      } else {
        sourceId = await context.read<ScheduleProvider>().addSchedule(schedule);
      }

      // 批量复制
      final count = await context
          .read<ScheduleProvider>()
          .batchCopySchedule(schedule.copyWith(id: sourceId), result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功复制到 $count 天')),
        );
        Navigator.pop(context, true);
      }
    }
  }
}
