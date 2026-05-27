import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/dual_calendar.dart';
import '../widgets/day_view.dart';
import '../utils/constants.dart';
import 'schedule_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _CopyPhase { none, source, target }

class _HomeScreenState extends State<HomeScreen> {
  int _viewMode = 0; // 0=月, 1=日

  static const _modeLabels = ['月视图', '日视图'];
  static const _modeIcons = [
    Icons.calendar_view_month,
    Icons.calendar_view_day,
  ];

  // 复制模式状态
  bool get _isCopyMode => _copyPhase != _CopyPhase.none;
  _CopyPhase _copyPhase = _CopyPhase.none;
  DateTime? _sourceStart;
  DateTime? _sourceEnd;
  DateTime? _targetStart;
  DateTime? _targetEnd;

  // 清空模式状态
  bool _isClearMode = false;
  DateTime? _clearStart;
  DateTime? _clearEnd;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = context.read<ScheduleProvider>();
    provider.selectDate(DateTime.now());
    provider.loadAllDates();
  }

  void _switchMode() {
    setState(() {
      _viewMode = (_viewMode + 1) % 2;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _viewMode = 1;
    });
  }

  void _enterCopyMode() {
    setState(() {
      _exitClearMode();
      _copyPhase = _CopyPhase.source;
      _sourceStart = null;
      _sourceEnd = null;
      _targetStart = null;
      _targetEnd = null;
    });
  }

  void _exitCopyMode() {
    setState(() {
      _copyPhase = _CopyPhase.none;
      _sourceStart = null;
      _sourceEnd = null;
      _targetStart = null;
      _targetEnd = null;
    });
  }

  void _enterClearMode() {
    setState(() {
      _isClearMode = true;
      _clearStart = null;
      _clearEnd = null;
      _exitCopyMode();
    });
  }

  void _exitClearMode() {
    setState(() {
      _isClearMode = false;
      _clearStart = null;
      _clearEnd = null;
    });
  }

  void _onClearDateTap(DateTime date) {
    setState(() {
      if (_clearStart == null) {
        _clearStart = date;
        _clearEnd = null;
      } else if (_clearEnd == null) {
        if (date.isBefore(_clearStart!)) {
          _clearEnd = _clearStart;
          _clearStart = date;
        } else {
          _clearEnd = date;
        }
      } else {
        _clearStart = date;
        _clearEnd = null;
      }
    });
  }

  Future<void> _confirmClear() async {
    if (_clearStart == null || _clearEnd == null) return;
    final days = _clearEnd!.difference(_clearStart!).inDays + 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空日程'),
        content: Text('确定要删除 ${_clearStart!.month}/${_clearStart!.day} 至 ${_clearEnd!.month}/${_clearEnd!.day}（$days天）的所有日程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('全部删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<ScheduleProvider>();
    final count = await provider.deleteByDateRange(_clearStart!, _clearEnd!);
    _exitClearMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清空 $count 个日程')),
      );
    }
  }

  void _onCopyDateTap(DateTime date) {
    setState(() {
      if (_copyPhase == _CopyPhase.source) {
        if (_sourceStart == null) {
          _sourceStart = date;
          _sourceEnd = null;
        } else if (_sourceEnd == null) {
          if (date.isBefore(_sourceStart!)) {
            _sourceEnd = _sourceStart;
            _sourceStart = date;
          } else {
            _sourceEnd = date;
          }
        } else {
          _sourceStart = date;
          _sourceEnd = null;
        }
      } else if (_copyPhase == _CopyPhase.target) {
        if (_targetStart == null) {
          _targetStart = date;
          _targetEnd = null;
        } else if (_targetEnd == null) {
          if (date.isBefore(_targetStart!)) {
            _targetEnd = _targetStart;
            _targetStart = date;
          } else {
            _targetEnd = date;
          }
        } else {
          _targetStart = date;
          _targetEnd = null;
        }
      }
    });
  }

  void _toTargetPhase() {
    if (_sourceStart == null || _sourceEnd == null) return;
    setState(() {
      _copyPhase = _CopyPhase.target;
      _targetStart = null;
      _targetEnd = null;
    });
  }

  void _backToSourcePhase() {
    setState(() {
      _copyPhase = _CopyPhase.source;
      _targetStart = null;
      _targetEnd = null;
    });
  }

  int get _sourceLen {
    if (_sourceStart == null || _sourceEnd == null) return 0;
    return _sourceEnd!.difference(_sourceStart!).inDays + 1;
  }

  int get _targetLen {
    if (_targetStart == null || _targetEnd == null) return 0;
    return _targetEnd!.difference(_targetStart!).inDays + 1;
  }

  Future<void> _confirmCopy() async {
    if (_sourceStart == null || _sourceEnd == null ||
        _targetStart == null || _targetEnd == null) return;

    final srcLen = _sourceLen;
    final tgtLen = _targetLen;

    if (tgtLen % srcLen != 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('目标范围（$tgtLen天）必须是源范围（$srcLen天）的整数倍'),
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认复制日程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow(Icons.file_copy, '复制的日程范围',
                '${_sourceStart!.month}/${_sourceStart!.day} - ${_sourceEnd!.month}/${_sourceEnd!.day}（$srcLen天）'),
            const SizedBox(height: 12),
            _confirmRow(Icons.content_paste, '目标范围',
                '${_targetStart!.month}/${_targetStart!.day} - ${_targetEnd!.month}/${_targetEnd!.day}（$tgtLen天）'),
            const SizedBox(height: 16),
            Text(
              '将源范围中每一天的日程按顺序循环复制到目标范围',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认复制'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final provider = context.read<ScheduleProvider>();
      final count = await provider.batchCopyDateRange(
        sourceStart: _sourceStart!,
        sourceEnd: _sourceEnd!,
        targetStart: _targetStart!,
        targetEnd: _targetEnd!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功复制 $count 个日程')),
        );
      }

      _exitCopyMode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制失败: $e')),
        );
      }
    }
  }

  Widget _confirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Future<void> _clearDaySchedules(BuildContext context) async {
    final provider = context.read<ScheduleProvider>();
    final date = provider.selectedDate;
    final schedules = provider.currentSchedules.toList();
    if (schedules.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空当日日程'),
        content: Text('确定要删除 ${date.month}月${date.day}日的所有 ${schedules.length} 个日程吗？'),
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
            child: const Text('全部删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ids = schedules.map((s) => s.id).whereType<int>().toList();
      for (final id in ids) {
        await provider.deleteSchedule(id);
      }
    }
  }

  /// 清空模式操作提示横幅
  Widget _buildClearModeBanner() {
    final rangeComplete = _clearStart != null && _clearEnd != null;
    final len = _clearStart != null && _clearEnd != null
        ? _clearEnd!.difference(_clearStart!).inDays + 1
        : 0;

    String instruction;
    if (_clearStart == null) {
      instruction = '请点击选择要清空的开始日期';
    } else if (_clearEnd == null) {
      instruction = '请点击选择要清空的结束日期（已选 ${_clearStart!.month}/${_clearStart!.day}）';
    } else {
      instruction = '已选范围 $len 天（${_clearStart!.month}/${_clearStart!.day} - ${_clearEnd!.month}/${_clearEnd!.day}）';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.red.withOpacity(0.08),
      child: Row(
        children: [
          const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择要清空的日程范围',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  instruction,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _exitClearMode,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('取消', style: TextStyle(fontSize: 12)),
          ),
          if (rangeComplete)
            TextButton(
              onPressed: _confirmClear,
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('确认清空', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  /// 第二层工具栏：模式切换、搜索、复制/清空
  Widget _buildSecondaryToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toolbarButton(
            icon: _modeIcons[_viewMode],
            label: _modeLabels[_viewMode],
            onTap: _switchMode,
          ),
          _toolbarButton(
            icon: Icons.search,
            label: '搜索',
            onTap: () => _showSearch(context),
          ),
          if (_viewMode == 0)
            _toolbarButton(
              icon: _isCopyMode ? Icons.content_copy : Icons.file_copy_outlined,
              label: _isCopyMode ? '复制中' : '复制',
              color: _isCopyMode ? AppConstants.primaryColor : null,
              onTap: _isCopyMode ? _exitCopyMode : _enterCopyMode,
            ),
          if (_viewMode == 0)
            _toolbarButton(
              icon: Icons.delete_sweep,
              label: _isClearMode ? '清空中' : '清空',
              color: _isClearMode ? Colors.red : null,
              onTap: _isClearMode ? _exitClearMode : _enterClearMode,
            ),
          if (_viewMode == 1)
            _toolbarButton(
              icon: Icons.delete_sweep,
              label: '清空',
              onTap: () => _clearDaySchedules(context),
            ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Icon(icon, size: 22, color: color ?? AppConstants.textPrimary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color ?? AppConstants.textPrimary),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthView(ScheduleProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadAllDates();
        await provider.loadDatesForMonth(
          DateTime.now().year,
          DateTime.now().month,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            DualCalendar(
              onDateSelected: _onDateSelected,
              isCopyMode: _isCopyMode,
              copyRangeStart: _copyPhase == _CopyPhase.source ? _sourceStart : _targetStart,
              copyRangeEnd: _copyPhase == _CopyPhase.source ? _sourceEnd : _targetEnd,
              onCopyDateTap: _isClearMode ? _onClearDateTap : _onCopyDateTap,
              isClearMode: _isClearMode,
              clearRangeStart: _clearStart,
              clearRangeEnd: _clearEnd,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyModeBanner() {
    final isSourcePhase = _copyPhase == _CopyPhase.source;
    final start = isSourcePhase ? _sourceStart : _targetStart;
    final end = isSourcePhase ? _sourceEnd : _targetEnd;
    final len = isSourcePhase ? _sourceLen : _targetLen;
    final rangeComplete = start != null && end != null;

    String instruction;
    if (start == null) {
      instruction = isSourcePhase
          ? '请点击选择要复制的开始日期'
          : '请点击选择目标范围的开始日期';
    } else if (end == null) {
      instruction = isSourcePhase
          ? '请点击选择要复制的结束日期（已选 ${start.month}/${start.day}）'
          : '请点击选择目标范围的结束日期（已选 ${start.month}/${start.day}）';
    } else {
      instruction = isSourcePhase
          ? '已选源范围 ${len} 天（${start.month}/${start.day} - ${end.month}/${end.day}）'
          : '已选目标范围 ${len} 天（${start.month}/${start.day} - ${end.month}/${end.day}）';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppConstants.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            isSourcePhase ? Icons.file_copy : Icons.content_paste,
            size: 16,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSourcePhase ? '选择复制的日程范围' : '选择目标范围',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                Text(
                  instruction,
                  style: const TextStyle(fontSize: 12, color: AppConstants.primaryColor),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _exitCopyMode,
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('取消', style: TextStyle(fontSize: 12)),
          ),
          if (isSourcePhase && rangeComplete)
            TextButton(
              onPressed: _toTargetPhase,
              style: TextButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('下一步', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          if (!isSourcePhase && rangeComplete)
            TextButton(
              onPressed: _backToSourcePhase,
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('返回', style: TextStyle(fontSize: 12)),
            ),
          if (!isSourcePhase && rangeComplete)
            TextButton(
              onPressed: _confirmCopy,
              style: TextButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('确认', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          '亲子时光',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildSecondaryToolbar(),
              if (_isCopyMode)
                _buildCopyModeBanner(),
              if (_isClearMode)
                _buildClearModeBanner(),
              Expanded(
                child: _viewMode == 0
                    ? _buildMonthView(provider)
                    : const DayView(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isCopyMode
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final selectedDate = context.read<ScheduleProvider>().selectedDate;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleFormScreen(initialDate: selectedDate),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜索日程'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入标题或描述...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.isNotEmpty) {
                _showSearchResults(controller.text);
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(String keyword) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder(
          future: context.read<ScheduleProvider>().searchSchedules(keyword),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final results = snapshot.data!;
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '搜索 "$keyword" 共 ${results.length} 条结果',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final schedule = results[index];
                          return ListTile(
                            leading: Container(
                              width: 4,
                              height: 40,
                              color: AppConstants.getCategoryColorByName(
                                  schedule.category),
                            ),
                            title: Text(schedule.title),
                            subtitle: Text(
                              '${schedule.date} ${schedule.startTime ?? ''}',
                            ),
                            onTap: () {
                              final date = DateTime.tryParse(schedule.date);
                              if (date != null) {
                                context
                                    .read<ScheduleProvider>()
                                    .selectDate(date);
                              }
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
