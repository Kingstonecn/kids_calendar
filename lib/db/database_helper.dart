import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kids_calendar.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        category TEXT DEFAULT '其他',
        color_index INTEGER DEFAULT 0,
        is_repeating INTEGER DEFAULT 0,
        repeat_rule TEXT,
        has_alarm INTEGER DEFAULT 0,
        alarm_minutes_before INTEGER,
        source_id INTEGER,
        is_completed INTEGER DEFAULT 0,
        app_package_name TEXT,
        app_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_schedules_date ON schedules(date)');
    await db.execute('CREATE INDEX idx_schedules_source ON schedules(source_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE schedules ADD COLUMN app_package_name TEXT');
      await db.execute('ALTER TABLE schedules ADD COLUMN app_name TEXT');
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
