import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../db/schedule_dao.dart';
import '../utils/date_utils.dart' as date_utils;

class ScheduleProvider extends ChangeNotifier {
  final ScheduleDao _dao = ScheduleDao();

  List<Schedule> _currentSchedules = [];
  List<String> _datesWithSchedules = [];
  Map<String, List<Schedule>> _monthSchedules = {};
  List<Schedule> _agendaSchedules = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Getters
  List<Schedule> get currentSchedules => _currentSchedules;
  List<String> get datesWithSchedules => _datesWithSchedules;
  Map<String, List<Schedule>> get monthSchedules => _monthSchedules;
  List<Schedule> get agendaSchedules => _agendaSchedules;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  /// 选中日期并加载日程
  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await loadSchedulesForDate(date);
  }

  /// 加载指定日期的日程
  Future<void> loadSchedulesForDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    final dateStr = date_utils.DateUtils.formatDate(date);
    _currentSchedules = await _dao.getByDate(dateStr);

    _isLoading = false;
    notifyListeners();
  }

  /// 加载指定月份有日程的日期及日程详情
  Future<void> loadDatesForMonth(int year, int month) async {
    final schedules = await _dao.getByMonth(year, month);
    _datesWithSchedules = schedules.map((s) => s.date).toSet().toList();

    _monthSchedules = {};
    for (final s in schedules) {
      _monthSchedules.putIfAbsent(s.date, () => []).add(s);
    }
    notifyListeners();
  }

  /// 获取所有日程日期
  Future<void> loadAllDates() async {
    _datesWithSchedules = await _dao.getAllDates();
    notifyListeners();
  }

  /// 加载日程列表（前后各一年）
  Future<void> loadAgendaSchedules() async {
    final today = DateTime.now();
    final start = DateTime(today.year - 1, today.month, today.day);
    final end = DateTime(today.year + 1, today.month, today.day);
    _agendaSchedules = await _dao.getByDateRange(
      date_utils.DateUtils.formatDate(start),
      date_utils.DateUtils.formatDate(end),
    );
    notifyListeners();
  }

  /// 添加日程
  Future<int> addSchedule(Schedule schedule) async {
    final id = await _dao.insert(schedule);
    schedule.id = id;
    await loadSchedulesForDate(_selectedDate);
    await loadAllDates();
    return id;
  }

  /// 更新日程
  Future<void> updateSchedule(Schedule schedule) async {
    await _dao.update(schedule);
    await loadSchedulesForDate(_selectedDate);
    await loadAllDates();
  }

  /// 删除日程
  Future<void> deleteSchedule(int id) async {
    await _dao.delete(id);
    await loadSchedulesForDate(_selectedDate);
    await loadAllDates();
  }

  /// 批量复制日程到多个日期
  Future<int> batchCopySchedule(Schedule source, List<DateTime> targetDates) async {
    final schedules = <Schedule>[];
    for (final date in targetDates) {
      final copy = source.copyWith(
        id: null,
        date: date_utils.DateUtils.formatDate(date),
        sourceId: source.id,
        isCompleted: false,
        createdAt: null,
        updatedAt: null,
      );
      schedules.add(copy);
    }
    final ids = await _dao.insertAll(schedules);
    await loadSchedulesForDate(_selectedDate);
    await loadAllDates();
    return ids.length;
  }

  /// 获取某日的日程列表
  Future<List<Schedule>> getSchedulesForDate(DateTime date) async {
    final dateStr = date_utils.DateUtils.formatDate(date);
    return await _dao.getByDate(dateStr);
  }

  /// 搜索日程
  Future<List<Schedule>> searchSchedules(String keyword) async {
    return await _dao.search(keyword);
  }
}
