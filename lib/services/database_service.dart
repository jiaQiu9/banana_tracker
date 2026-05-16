import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/banana_entry.dart';

class DatabaseService {
  static const int _dbVersion = 1;
  static Database? _db;
  static Future<Database>? _dbFuture;
  static final DatabaseService _instance = DatabaseService._();
  DatabaseService._();
  factory DatabaseService() => _instance;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _dbFuture ??= _init();
    _db = await _dbFuture;
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'banana_tracker.db');
    print('[DB] Opening database at: $path');
    return openDatabase(path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE banana_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eaten_at TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 1.0
      )
    ''');
  }

  // DATABASE VERSION HISTORY
  // v1 — baseline: banana_logs (id, eaten_at TEXT, amount REAL)
  // v2 — (future)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // future migration
    }
    if (oldVersion < 3) {
      // future migration
    }
  }

  String _todayDate() => DateTime.now().toIso8601String().split('T')[0];

  Future<void> logBanana(double amount) async {
    final db = await database;
    await db.insert('banana_logs', {
      'eaten_at': DateTime.now().toIso8601String(),
      'amount': amount,
    });
  }

  Future<void> undoLastLog() async {
    final db = await database;
    await db.rawDelete(
      'DELETE FROM banana_logs WHERE id = (SELECT MAX(id) FROM banana_logs)',
    );
  }

  Future<List<BananaEntry>> getTodayTimestamps() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT eaten_at, amount FROM banana_logs WHERE date(eaten_at) = ? ORDER BY eaten_at ASC",
      [_todayDate()],
    );
    return result.map((r) => BananaEntry.fromMap(r)).toList();
  }

  Future<double> getTodayCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) AS total FROM banana_logs WHERE date(eaten_at) = ?",
      [_todayDate()],
    );
    final total = result.first['total'];
    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<List<BananaEntry>> getHistory({int days = 30}) async {
    final db = await database;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      "SELECT date(eaten_at) AS d, SUM(amount) AS total FROM banana_logs "
      "WHERE date(eaten_at) BETWEEN ? AND ? "
      "GROUP BY d ORDER BY d DESC",
      [startStr, endStr],
    );

    final entryMap = <String, double>{};
    for (final row in result) {
      entryMap[row['d'] as String] = (row['total'] as num).toDouble();
    }

    final filled = <BananaEntry>[];
    for (int i = 0; i < days; i++) {
      final d = end.subtract(Duration(days: i));
      final key = _dateKey(d);
      filled.add(BananaEntry(
        eatenAt: d,
        amount: entryMap[key] ?? 0.0,
      ));
    }
    return filled;
  }

  Future<List<BananaEntry>> getMonthEntries(int year, int month) async {
    final db = await database;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    final endStr = '$year-${month.toString().padLeft(2, '0')}-${daysInMonth.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      "SELECT date(eaten_at) AS d, SUM(amount) AS total FROM banana_logs "
      "WHERE date(eaten_at) BETWEEN ? AND ? "
      "GROUP BY d",
      [startStr, endStr],
    );

    final entryMap = <String, double>{};
    for (final row in result) {
      entryMap[row['d'] as String] = (row['total'] as num).toDouble();
    }

    final filled = <BananaEntry>[];
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final key = _dateKey(date);
      filled.add(BananaEntry(
        eatenAt: date,
        amount: entryMap[key] ?? 0.0,
      ));
    }
    return filled;
  }

  Future<Map<String, double>> getWeeklyTotals() async {
    final history = await getHistory(days: 30);
    final weekly = <String, double>{};
    for (final entry in history) {
      final weekStart = entry.eatenAt.subtract(Duration(days: entry.eatenAt.weekday - 1));
      final key = '${weekStart.month}/${weekStart.day}';
      weekly[key] = (weekly[key] ?? 0.0) + entry.amount;
    }
    return weekly;
  }

  Future<int> getStreak(double dailyGoal) async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT DATE(eaten_at) AS day FROM banana_logs "
      "GROUP BY DATE(eaten_at) "
      "HAVING SUM(amount) >= ? "
      "ORDER BY day DESC",
      [dailyGoal],
    );

    final qualifyingDays = result.map((r) => r['day'] as String).toSet();

    int streak = 0;
    DateTime d = DateTime.now();

    while (qualifyingDays.contains(_dateKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<bool> hadGoalReachedOnDate(DateTime date, double dailyGoal) async {
    final db = await database;
    final dateStr = _dateKey(date);
    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM banana_logs WHERE DATE(eaten_at) = ?',
      [dateStr],
    );
    final total = result.first['total'];
    return total != null && (total as num) >= dailyGoal;
  }

  Future<void> cleanupOldEntries() async {
    // No cleanup needed. All historical records must be preserved
    // for streak tracking, history screen, and nutrition summaries.
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
