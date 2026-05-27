import 'package:sqflite/sqflite.dart';
import '../models/schedule.dart';
import 'database_helper.dart';

class ScheduleDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db => _dbHelper.database;

  /// 插入日程
  Future<int> insert(Schedule schedule) async {
    final db = await _db;
    return await db.insert('schedules', schedule.toMap());
  }

  /// 批量插入日程
  Future<List<int>> insertAll(List<Schedule> schedules) async {
    final db = await _db;
    final batch = db.batch();
    for (final s in schedules) {
      batch.insert('schedules', s.toMap());
    }
    return (await batch.commit(noResult: false))
        .map((e) => e as int)
        .toList();
  }

  /// 更新日程
  Future<int> update(Schedule schedule) async {
    final db = await _db;
    schedule.updatedAt = DateTime.now().toIso8601String();
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// 删除日程
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// 根据ID查询
  Future<Schedule?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('schedules', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Schedule.fromMap(maps.first);
  }

  /// 查询指定日期的日程
  Future<List<Schedule>> getByDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'schedules',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'start_time ASC, created_at ASC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  /// 查询日期范围内的日程
  Future<List<Schedule>> getByDateRange(String startDate, String endDate) async {
    final db = await _db;
    final maps = await db.query(
      'schedules',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, start_time ASC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  /// 查询指定月份的日程 (用于日历标记)
  Future<List<Schedule>> getByMonth(int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = year == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    final db = await _db;
    final maps = await db.query(
      'schedules',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, start_time ASC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  /// 获取所有日程日期 (用于日历标记)
  Future<List<String>> getAllDates() async {
    final db = await _db;
    final maps = await db.rawQuery('SELECT DISTINCT date FROM schedules');
    return maps.map((m) => m['date'] as String).toList();
  }

  /// 搜索日程 (按标题或描述)
  Future<List<Schedule>> search(String keyword) async {
    final db = await _db;
    final maps = await db.query(
      'schedules',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'date DESC, start_time ASC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  /// 获取所有日程 (按日期倒序)
  Future<List<Schedule>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'schedules',
      orderBy: 'date DESC, start_time ASC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  /// 获取有提醒的日程
  Future<List<Schedule>> getSchedulesWithAlarm() async {
    final db = await _db;
    final maps = await db.query(
      'schedules',
      where: 'has_alarm = 1',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  /// 删除指定sourceId的所有复制日程
  Future<int> deleteBySourceId(int sourceId) async {
    final db = await _db;
    return await db.delete(
      'schedules',
      where: 'source_id = ?',
      whereArgs: [sourceId],
    );
  }

  /// 获取所有有日程的年份
  Future<List<int>> getYearsWithSchedules() async {
    final db = await _db;
    final maps = await db.rawQuery(
        "SELECT DISTINCT CAST(substr(date, 1, 4) AS INTEGER) as year FROM schedules ORDER BY year"
    );
    return maps.map((m) => m['year'] as int).toList();
  }

  /// 获取指定年份的分类统计
  Future<Map<String, int>> getCategoryStats(int year) async {
    final db = await _db;
    final startDate = '$year-01-01';
    final endDate = '${year + 1}-01-01';
    final maps = await db.query(
      'schedules',
      columns: ['category'],
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
    );
    final stats = <String, int>{};
    for (final row in maps) {
      final cat = (row['category'] as String?) ?? '其他';
      stats[cat] = (stats[cat] ?? 0) + 1;
    }
    return stats;
  }

  /// 获取指定年份每月的日程数和已打卡数
  Future<Map<int, Map<String, int>>> getMonthlyStats(int year) async {
    final db = await _db;
    final startDate = '$year-01-01';
    final endDate = '${year + 1}-01-01';
    final maps = await db.query(
      'schedules',
      columns: ['date', 'is_completed'],
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
    );
    final stats = <int, Map<String, int>>{};
    for (int m = 1; m <= 12; m++) {
      stats[m] = {'total': 0, 'completed': 0};
    }
    for (final row in maps) {
      final dateStr = row['date'] as String;
      final month = int.tryParse(dateStr.substring(5, 7)) ?? 0;
      if (month >= 1 && month <= 12) {
        stats[month]!['total'] = stats[month]!['total']! + 1;
        if ((row['is_completed'] as int?) == 1) {
          stats[month]!['completed'] = stats[month]!['completed']! + 1;
        }
      }
    }
    return stats;
  }
}
