import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/lunar_calendar.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/constants.dart';

class DualCalendar extends StatefulWidget {
  const DualCalendar({super.key});

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
  }

  /// 获取当月要显示的日期网格
  List<DateTime?> _getMonthGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 周日=0, 周一=1...
    final daysInMonth = lastDay.day;

    final grid = <DateTime?>[];
    // 上月补齐
    for (int i = startWeekday - 1; i >= 0; i--) {
      grid.add(DateTime(_currentMonth.year, _currentMonth.month, -i));
    }
    // 本月
    for (int d = 1; d <= daysInMonth; d++) {
      grid.add(DateTime(_currentMonth.year, _currentMonth.month, d));
    }
    // 下月补齐
    while (grid.length < 42) {
      final next = DateTime(_currentMonth.year, _currentMonth.month + 1,
          grid.length - startWeekday - daysInMonth + 1);
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

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    });
    _loadMonthData();
    context.read<ScheduleProvider>().selectDate(DateTime.now());
  }

  void _loadMonthData() {
    context
        .read<ScheduleProvider>()
        .loadDatesForMonth(_currentMonth.year, _currentMonth.month);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildWeekdayLabels(),
              _buildCalendarGrid(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppConstants.primaryColor),
            onPressed: _prevMonth,
          ),
          GestureDetector(
            onTap: _goToToday,
            child: Text(
              '${_currentMonth.year}年${_currentMonth.month}月',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppConstants.primaryColor),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays.map((d) {
          return Expanded(
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: d == '日' || d == '六'
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

  Widget _buildCalendarGrid(ScheduleProvider provider) {
    final grid = _getMonthGrid();
    final selectedDate = provider.selectedDate;
    final datesWithSchedules = provider.datesWithSchedules.toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.1,
        ),
        itemCount: grid.length,
        itemBuilder: (context, index) {
          final date = grid[index];
          if (date == null) return const SizedBox.shrink();

          final isCurrentMonth = date.month == _currentMonth.month;
          final isToday = date_utils.DateUtils.isSameDay(date, _today);
          final isSelected = date_utils.DateUtils.isSameDay(date, selectedDate);
          final hasSchedule = datesWithSchedules.contains(
            date_utils.DateUtils.formatDate(date),
          );
          final isWeekend = date.weekday == 6 || date.weekday == 7;

          // 获取农历
          final lunar = LunarCalendar.simpleLunar(
            date.year,
            date.month,
            date.day,
          );
          final festival = LunarCalendar.getLunarFestival(
            date.year,
            date.month,
            date.day,
          );

          return GestureDetector(
            onTap: () {
              provider.selectDate(date);
            },
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.15)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isToday)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
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
                  const SizedBox(height: 1),
                  if (festival != null)
                    Text(
                      festival,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppConstants.accentColor,
                      ),
                    )
                  else if (lunar.isNotEmpty)
                    Text(
                      lunar,
                      style: TextStyle(
                        fontSize: 8,
                        color: isCurrentMonth
                            ? AppConstants.textSecondary
                            : Colors.grey.shade300,
                      ),
                    ),
                  if (hasSchedule)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: const BoxDecoration(
                        color: AppConstants.accentColor,
                        shape: BoxShape.circle,
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
}
