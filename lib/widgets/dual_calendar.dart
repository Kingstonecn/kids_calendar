import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_themes.dart';
import '../utils/lunar_calendar.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/constants.dart';

class DualCalendar extends StatefulWidget {
  final ValueChanged<DateTime>? onDateSelected;
  final bool isCopyMode;
  final DateTime? copyRangeStart;
  final DateTime? copyRangeEnd;
  final ValueChanged<DateTime>? onCopyDateTap;
  final bool isClearMode;
  final DateTime? clearRangeStart;
  final DateTime? clearRangeEnd;

  const DualCalendar({
    super.key,
    this.onDateSelected,
    this.isCopyMode = false,
    this.copyRangeStart,
    this.copyRangeEnd,
    this.onCopyDateTap,
    this.isClearMode = false,
    this.clearRangeStart,
    this.clearRangeEnd,
  });

  @override
  State<DualCalendar> createState() => _DualCalendarState();
}

class _DualCalendarState extends State<DualCalendar> {
  late DateTime _currentMonth;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _today = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonthData());
  }

  /// 获取当月要显示的日期网格
  List<DateTime?> _getMonthGrid(int firstDayOfWeek) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    // firstDayOfWeek: 0=周日, 1=周一, 6=周六
    final offset = (firstDay.weekday - firstDayOfWeek + 7) % 7;
    final daysInMonth = lastDay.day;

    final grid = <DateTime?>[];
    // 上月补齐
    for (int i = offset - 1; i >= 0; i--) {
      grid.add(DateTime(_currentMonth.year, _currentMonth.month, -i));
    }
    // 本月
    for (int d = 1; d <= daysInMonth; d++) {
      grid.add(DateTime(_currentMonth.year, _currentMonth.month, d));
    }
    // 下月补齐
    while (grid.length < 42) {
      final next = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
        grid.length - offset - daysInMonth + 1,
      );
      grid.add(next);
    }
    return grid;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadMonthData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadMonthData();
  }

  Future<void> _pickMonth() async {
    int year = _currentMonth.year;
    int month = _currentMonth.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('选择月份'),
                  content: SizedBox(
                    width: 280,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => setDialogState(() => year--),
                            ),
                            Text(
                              '$year年',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => setDialogState(() => year++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(12, (i) {
                            final m = i + 1;
                            final isSelected =
                                m == month && year == _currentMonth.year;
                            return OutlinedButton(
                              onPressed:
                                  () =>
                                      Navigator.pop(ctx, DateTime(year, m, 1)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor:
                                    isSelected
                                        ? AppConstants.primaryColor.withOpacity(
                                          0.12,
                                        )
                                        : null,
                                side:
                                    isSelected
                                        ? BorderSide(
                                          color: AppConstants.primaryColor,
                                          width: 1.5,
                                        )
                                        : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                '${m}月',
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppConstants.primaryColor
                                          : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentMonth = result;
      });
      _loadMonthData();
    }
  }

  void _loadMonthData() {
    context.read<ScheduleProvider>().loadDatesForMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final config = provider.currentConfig;
    final firstDayOfWeek = provider.firstDayOfWeek;
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(config.containerRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GestureDetector(
            onHorizontalDragEnd: (d) {
              final dx = d.primaryVelocity ?? 0;
              if (dx < -200)
                _nextMonth();
              else if (dx > 200)
                _prevMonth();
            },
            onVerticalDragEnd: (d) {
              final dy = d.primaryVelocity ?? 0;
              if (dy < -200)
                _nextMonth();
              else if (dy > 200)
                _prevMonth();
            },
            child: _buildMonthBody(firstDayOfWeek, scheduleProvider, config),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickMonth,
            child: Text(
              '${_currentMonth.year}年${_currentMonth.month}月',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels(int firstDayOfWeek) {
    const allWeekdays = ['日', '一', '二', '三', '四', '五', '六'];
    final weekdays = [
      for (int i = 0; i < 7; i++) allWeekdays[(firstDayOfWeek + i) % 7],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children:
            weekdays.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          d == '日' || d == '六'
                              ? AppConstants.accentColor
                              : AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildMonthBody(
    int firstDayOfWeek,
    ScheduleProvider provider,
    CalendarThemeConfig config,
  ) {
    return Column(
      key: ValueKey('${_currentMonth.year}_${_currentMonth.month}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildWeekdayLabels(firstDayOfWeek),
        _buildCalendarGrid(provider, config, firstDayOfWeek),
      ],
    );
  }

  Widget _buildCalendarGrid(
    ScheduleProvider provider,
    CalendarThemeConfig config,
    int firstDayOfWeek,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final lunarDisplayMode = themeProvider.lunarDisplayMode;
    final grid = _getMonthGrid(firstDayOfWeek);
    final selectedDate = provider.selectedDate;
    final monthSchedules = provider.monthSchedules;

    // 根据屏幕尺寸动态计算单元格高度，确保6行完整显示
    final screenSize = MediaQuery.of(context).size;
    final cellWidth = (screenSize.width - 32) / 7;
    final cellHeight = (screenSize.height * 0.085).clamp(55.0, 120.0);
    final ratio = cellWidth / cellHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: ratio,
        ),
        itemCount: grid.length,
        itemBuilder: (context, index) {
          final date = grid[index];
          if (date == null) return const SizedBox.shrink();

          final isCurrentMonth = date.month == _currentMonth.month;
          final isToday = date_utils.DateUtils.isSameDay(date, _today);
          final isSelected = date_utils.DateUtils.isSameDay(date, selectedDate);
          final isWeekend = date.weekday == 6 || date.weekday == 7;
          final isInCopyRange = widget.isCopyMode &&
              widget.copyRangeStart != null &&
              (widget.copyRangeEnd == null
                  ? date_utils.DateUtils.isSameDay(date, widget.copyRangeStart!)
                  : !date.isBefore(widget.copyRangeStart!) &&
                      !date.isAfter(widget.copyRangeEnd!));
          final isInClearRange = widget.isClearMode &&
              widget.clearRangeStart != null &&
              (widget.clearRangeEnd == null
                  ? date_utils.DateUtils.isSameDay(date, widget.clearRangeStart!)
                  : !date.isBefore(widget.clearRangeStart!) &&
                      !date.isAfter(widget.clearRangeEnd!));

          final dateStr = date_utils.DateUtils.formatDate(date);
          final daySchedules = monthSchedules[dateStr] ?? [];

          // 获取农历
          final lunar = LunarCalendar.simpleLunar(
            date.year,
            date.month,
            date.day,
          );
          // 优先显示法定假日, 不显示农历
          final legalHoliday = LunarCalendar.getLegalHoliday(
            date.year,
            date.month,
            date.day,
          );
          final isHoliday = legalHoliday != null;

          final displaySchedules = daySchedules.take(3).toList();
          final hasMore = daySchedules.length > 3;

          return GestureDetector(
            onTap: () {
              if (widget.isCopyMode) {
                widget.onCopyDateTap?.call(date);
              } else if (widget.isClearMode) {
                widget.onCopyDateTap?.call(date);
              } else {
                provider.selectDate(date);
                widget.onDateSelected?.call(date);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(1),
              padding: const EdgeInsets.only(
                top: 2,
                left: 1,
                right: 1,
                bottom: 2,
              ),
              decoration: BoxDecoration(
                color: isInClearRange
                    ? Colors.red.withOpacity(0.25)
                    : isInCopyRange
                        ? Colors.amber.withOpacity(0.35)
                        : isSelected
                            ? AppConstants.primaryColor.withOpacity(0.12)
                            : null,
                borderRadius: BorderRadius.circular(config.cellRadius),
              ),
              child: Column(
                children: [
                  // 日期数字
                  SizedBox(
                    width: config.useCompactDate ? 20 : 24,
                    height: config.useCompactDate ? 20 : 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isToday)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color:
                                isToday
                                    ? Colors.white
                                    : !isCurrentMonth
                                    ? Colors.grey.shade300
                                    : isWeekend
                                    ? AppConstants.accentColor
                                    : AppConstants.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (lunarDisplayMode == 2)
                    const SizedBox(height: 7)
                  else if (lunarDisplayMode == 0 && isHoliday)
                    Text(
                      legalHoliday!,
                      style: TextStyle(
                        fontSize: 7,
                        height: 1.0,
                        color: isCurrentMonth
                            ? AppConstants.accentColor
                            : AppConstants.accentColor.withOpacity(0.4),
                      ),
                    )
                  else if (lunar.isNotEmpty)
                    Text(
                      lunar,
                      style: TextStyle(
                        fontSize: 7,
                        height: 1.0,
                        color: isCurrentMonth
                            ? AppConstants.textPrimary
                            : Colors.grey.shade300,
                      ),
                    )
                  else
                    const SizedBox(height: 7),
                  const SizedBox(height: 1),
                  // 日程横条 (Outlook 风格)
                  ...displaySchedules.map(
                    (s) => _buildScheduleBar(s, !isCurrentMonth, config),
                  ),
                  if (hasMore)
                    Text(
                      '+${daySchedules.length - 3}',
                      style: const TextStyle(
                        fontSize: 7,
                        height: 1.2,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 日程横条: 左侧色条 + 背景色 + 标题(限制字数)
  Widget _buildScheduleBar(
    Schedule schedule,
    bool faded,
    CalendarThemeConfig config,
  ) {
    final color = AppConstants.getCategoryColorByName(schedule.category);
    return Container(
      height: 11,
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(faded ? 0.08 : 0.18),
        borderRadius: BorderRadius.circular(config.barRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 7,
            decoration: BoxDecoration(
              color: color.withOpacity(faded ? 0.4 : 1.0),
              borderRadius: BorderRadius.circular(config.barRadius),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              schedule.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: config.barFontSize,
                height: 1.2,
                color: faded ? Colors.grey.shade400 : AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
