import 'package:flutter/material.dart';
import '../utils/lunar_calendar.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/constants.dart';

/// 小日历弹窗 — 用于选择要复制到的目标日期
class MiniCalendarDialog extends StatefulWidget {
  final DateTime sourceDate;
  final DateTime? repeatEndDate;
  final List<String> existingDates;

  const MiniCalendarDialog({
    super.key,
    required this.sourceDate,
    this.repeatEndDate,
    this.existingDates = const [],
  });

  @override
  State<MiniCalendarDialog> createState() => _MiniCalendarDialogState();
}

class _MiniCalendarDialogState extends State<MiniCalendarDialog> {
  late DateTime _currentMonth;
  final Set<DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.sourceDate.year, widget.sourceDate.month, 1);
  }

  List<DateTime?> _getMonthGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;
    final grid = <DateTime?>[];
    for (int i = startWeekday - 1; i >= 0; i--) {
      grid.add(DateTime(_currentMonth.year, _currentMonth.month, -i));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      grid.add(DateTime(_currentMonth.year, _currentMonth.month, d));
    }
    while (grid.length < 42) {
      final next = DateTime(_currentMonth.year, _currentMonth.month + 1,
          grid.length - startWeekday - daysInMonth + 1);
      grid.add(next);
    }
    return grid;
  }

  void _toggleDate(DateTime date) {
    // 校验: 目标日期不能早于源日期
    if (date.isBefore(widget.sourceDate)) return;

    setState(() {
      if (_selectedDates.contains(date)) {
        _selectedDates.remove(date);
      } else {
        _selectedDates.add(date);
      }
    });
  }

  void _selectAllRemaining() {
    // 选择从源日期到当前显示月份末的所有日期
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    setState(() {
      for (var d = DateTime(
          widget.sourceDate.year, widget.sourceDate.month, widget.sourceDate.day);
          !d.isAfter(lastDay);
          d = d.add(const Duration(days: 1))) {
        _selectedDates.add(d);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDates.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 340),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择复制日期',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '已选 ${_selectedDates.length} 天',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(),
            // 月份导航
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _currentMonth = DateTime(
                        _currentMonth.year, _currentMonth.month - 1, 1);
                  }),
                ),
                Text(
                  '${_currentMonth.year}年${_currentMonth.month}月',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _currentMonth = DateTime(
                        _currentMonth.year, _currentMonth.month + 1, 1);
                  }),
                ),
              ],
            ),
            // 星期标签
            Row(
              children: ['日', '一', '二', '三', '四', '五', '六'].map((d) {
                return Expanded(
                  child: Center(
                    child: Text(d, style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            // 日期网格
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.3,
                ),
                itemCount: 42,
                itemBuilder: (context, index) {
                  final grid = _getMonthGrid();
                  if (index >= grid.length) return const SizedBox();
                  final date = grid[index];
                  if (date == null) return const SizedBox();

                  final isCurrentMonth = date.month == _currentMonth.month;
                  final isBeforeSource = date.isBefore(widget.sourceDate);
                  final isSelected = _selectedDates.contains(date);
                  final lunar = LunarCalendar.simpleLunar(
                      date.year, date.month, date.day);

                  return GestureDetector(
                    onTap: isBeforeSource || !isCurrentMonth
                        ? null
                        : () => _toggleDate(date),
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryColor.withOpacity(0.2)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: !isCurrentMonth
                                  ? Colors.grey.shade300
                                  : isBeforeSource
                                      ? Colors.grey.shade300
                                      : isSelected
                                          ? AppConstants.primaryColor
                                          : null,
                              fontWeight:
                                  isSelected ? FontWeight.bold : null,
                            ),
                          ),
                          Text(
                            lunar,
                            style: TextStyle(
                              fontSize: 7,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('清空'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _selectAllRemaining,
                      child: const Text('全选'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _selectedDates.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop(_selectedDates.toList());
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('复制 (${_selectedDates.length})'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
