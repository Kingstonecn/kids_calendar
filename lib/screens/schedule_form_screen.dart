import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../services/notification_service.dart';
import '../widgets/category_picker.dart';
import '../widgets/mini_calendar_dialog.dart';
import '../widgets/app_picker_dialog.dart';
import '../utils/constants.dart';

class ScheduleFormScreen extends StatefulWidget {
  final Schedule? schedule;
  final DateTime? initialDate;
  const ScheduleFormScreen({super.key, this.schedule, this.initialDate});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late TimeOfDay? _startTime;
  late int _durationMinutes; // -1 = 全天, 0+ = 持续分钟数
  late String _category;
  late int _colorIndex;
  late bool _hasAlarm;
  late int? _alarmMinutesBefore;
  String? _appPackageName;
  String? _appName;
  bool _isEditing = false;

  static const String _allDayLabel = '全天';
  static const List<int> _durationOptions = [
    -1, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 360, 420, 480, 540, 600,
  ];

  static final List<TimeOfDay> _timeOptions = () {
    final times = <TimeOfDay>[];
    for (int h = 8; h <= 23; h++) {
      times.add(TimeOfDay(hour: h, minute: 0));
      times.add(TimeOfDay(hour: h, minute: 30));
    }
    return times;
  }();

  String _timeLabel(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

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
        : widget.initialDate ?? DateTime.now();
    _startTime = schedule?.startTime != null
        ? _parseTime(schedule!.startTime!)
        : null;

    // 计算时长: 新建默认30分钟; 编辑时有起止时间则算差值, 否则为全天
    if (widget.schedule == null) {
      _durationMinutes = 30;
    } else if (schedule?.startTime != null && schedule?.endTime != null) {
      final st = _parseTime(schedule!.startTime!);
      final et = _parseTime(schedule.endTime!);
      if (st != null && et != null) {
        _durationMinutes = (et.hour * 60 + et.minute) - (st.hour * 60 + st.minute);
        if (_durationMinutes <= 0) _durationMinutes = 30;
      } else {
        _durationMinutes = -1;
      }
    } else {
      _durationMinutes = -1;
    }

    _category = schedule?.category ?? '亲子';
    _colorIndex = schedule?.colorIndex ?? 0;
    _hasAlarm = schedule?.hasAlarm ?? false;
    _alarmMinutesBefore = schedule?.alarmMinutesBefore ?? 15;
    _appPackageName = schedule?.appPackageName;
    _appName = schedule?.appName;
  }

  TimeOfDay? _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _durationLabel(int minutes) {
    if (minutes == -1) return _allDayLabel;
    if (minutes < 60) return '${minutes}分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}小时' : '$h小时${m}分';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  TimeOfDay? get _endTime {
    if (_startTime == null || _durationMinutes == -1) return null;
    final total = _startTime!.hour * 60 + _startTime!.minute + _durationMinutes;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑日程' : '新增日程'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
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
              // ═══ 日期选择（最上方）═══
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
                ),
                child: InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppConstants.primaryColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('日期',
                              style: TextStyle(fontSize: 12,
                                  color: AppConstants.textSecondary)),
                          Text(
                            _displayDateFormat.format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppConstants.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ═══ 标题 ═══
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

              // ═══ 描述 ═══
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '输入日程描述（可选）',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // ═══ 开始时间 + 时长（一行）═══
              Row(
                children: [
                  // 开始时间
                  Expanded(
                    child: _buildSelector(
                      icon: Icons.access_time,
                      label: '开始时间',
                      value: _startTime != null
                          ? _startTime!.format(context)
                          : '请选择',
                      onTap: () => _showTimePicker(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 时长
                  Expanded(
                    child: _buildSelector(
                      icon: Icons.timer_outlined,
                      label: '时长',
                      value: _durationLabel(_durationMinutes),
                      onTap: _showDurationPicker,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ═══ 分类 ═══
              const Text('分类',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary)),
              const SizedBox(height: 8),
              CategoryPicker(
                selectedCategory: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 16),

              // ═══ 关联应用 ═══
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _showAppPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android,
                          size: 20, color: AppConstants.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('关联应用',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppConstants.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              _appName ?? '选择关联应用（可选）',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _appName != null
                                    ? AppConstants.textPrimary
                                    : AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_appPackageName != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _appPackageName = null;
                              _appName = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          size: 20, color: AppConstants.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ═══ 提醒 ═══
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

              // ═══ 保存按钮 ═══
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

  Widget _buildSelector({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppConstants.textSecondary)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down,
                size: 20, color: AppConstants.textSecondary),
          ],
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

  Future<void> _showTimePicker() async {
    final fixedItemExtent = 48.0;
    final initial = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
    var initialIdx = _timeOptions.indexWhere((t) =>
        t.hour == initial.hour && t.minute == initial.minute);
    if (initialIdx < 0) {
      initialIdx = 0;
      for (int i = 0; i < _timeOptions.length; i++) {
        final t = _timeOptions[i];
        if (t.hour * 60 + t.minute >= initial.hour * 60 + initial.minute) {
          initialIdx = i;
          break;
        }
      }
    }
    final controller = FixedExtentScrollController(initialItem: initialIdx);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentIdx = controller.hasClients
                ? controller.selectedItem
                : initialIdx;
            return Container(
              height: 320,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('选择开始时间',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            final idx = controller.hasClients
                                ? controller.selectedItem
                                : initialIdx;
                            final time = _timeOptions[
                                idx.clamp(0, _timeOptions.length - 1)];
                            Navigator.pop(ctx, time);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        setDialogState(() {});
                        return false;
                      },
                      child: ListWheelScrollView(
                        controller: controller,
                        itemExtent: fixedItemExtent,
                        perspective: 0.005,
                        diameterRatio: 1.5,
                        useMagnifier: true,
                        magnification: 1.1,
                        children: _timeOptions.map((t) {
                          final idx = _timeOptions.indexOf(t);
                          final isSelected = idx == currentIdx;
                          return Center(
                            child: Text(
                              _timeLabel(t),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppConstants.primaryColor
                                    : AppConstants.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is TimeOfDay) {
        setState(() => _startTime = result);
      }
    });
  }

  /// 时长选择底部弹窗 (滚动选择, 30分钟步进)
  void _showDurationPicker() {
    final fixedItemExtent = 48.0;
    final initialIndex = _durationOptions.indexOf(_durationMinutes);
    final controller = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 0,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentIdx = controller.hasClients
                ? controller.selectedItem
                : initialIndex >= 0
                    ? initialIndex
                    : 0;
            return Container(
              height: 320,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  // 标题 + 确认按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('选择时长',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            final idx = controller.hasClients
                                ? controller.selectedItem
                                : 0;
                            final duration = _durationOptions[
                                idx.clamp(0, _durationOptions.length - 1)];
                            Navigator.pop(ctx, duration);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // 滚动选择器
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        setDialogState(() {});
                        return false;
                      },
                      child: ListWheelScrollView(
                        controller: controller,
                        itemExtent: fixedItemExtent,
                        perspective: 0.005,
                        diameterRatio: 1.5,
                        useMagnifier: true,
                        magnification: 1.1,
                        children: _durationOptions.map((min) {
                          final idx = _durationOptions.indexOf(min);
                          final isSelected = idx == currentIdx;
                          return Center(
                            child: Text(
                              _durationLabel(min),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppConstants.primaryColor
                                    : AppConstants.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is int) {
        setState(() => _durationMinutes = result);
      }
    });
  }

  Future<void> _showAppPicker() async {
    final result = await AppPickerDialog.pick(
      context,
      currentPackageName: _appPackageName,
    );
    if (result != null && mounted) {
      setState(() {
        _appPackageName = result.$1;
        _appName = result.$2;
      });
    }
  }

  Future<void> _saveSchedule() async {
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
      isRepeating: widget.schedule?.isRepeating ?? false,
      repeatRule: widget.schedule?.repeatRule,
      sourceId: widget.schedule?.sourceId,
      isCompleted: widget.schedule?.isCompleted ?? false,
      appPackageName: _appPackageName,
      appName: _appName,
      createdAt: widget.schedule?.createdAt,
    );

    final provider = context.read<ScheduleProvider>();

    if (_isEditing) {
      await provider.updateSchedule(schedule);
    } else {
      final id = await provider.addSchedule(schedule);
      schedule.id = id;
    }

    if (_hasAlarm && schedule.id != null && _startTime != null) {
      final alarmDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime!.hour,
        _startTime!.minute,
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
      await NotificationService().cancelNotification(widget.schedule!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

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
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!_formKey.currentState!.validate()) return;

      final schedule = Schedule(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: _dateFormat.format(_selectedDate),
        startTime: _startTime?.format(context),
        endTime: _endTime?.format(context),
        category: _category,
        colorIndex: _colorIndex,
        hasAlarm: _hasAlarm,
        alarmMinutesBefore: _hasAlarm ? _alarmMinutesBefore : null,
        appPackageName: _appPackageName,
        appName: _appName,
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
