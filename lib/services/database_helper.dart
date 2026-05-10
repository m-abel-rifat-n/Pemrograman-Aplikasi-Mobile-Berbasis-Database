import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'doflow.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        reminder TEXT,
        category TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT
      )
    ''');
  }

  // ── Tasks CRUD ────────────────────────────────────────────

  Future<int> insertTask(Task task) async {
    final db = await database;
    return db.insert('tasks', task.toMap());
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'id DESC');
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    final db = await database;
    final rows = await db.query('tasks',
        where: 'category = ?', whereArgs: [category], orderBy: 'id DESC');
    return rows.map(Task.fromMap).toList();
  }

  Future<void> toggleDone(int id, bool isDone) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'is_done': isDone ? 1 : 0,
        'completed_at': isDone ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Stats ─────────────────────────────────────────────────

  Future<Map<String, int>> getTodayStats() async {
    final db = await database;
    final today = _dateStr(DateTime.now());
    final total = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM tasks WHERE due_date = ?', [today])) ??
        0;
    final done = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM tasks WHERE due_date = ? AND is_done = 1',
            [today])) ??
        0;
    return {'total': total, 'done': done, 'undone': total - done};
  }

  Future<List<int>> getWeeklyTaskCounts() async {
    final db = await database;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final counts = <int>[];
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final count = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM tasks WHERE due_date = ? AND is_done = 1',
              [_dateStr(day)])) ??
          0;
      counts.add(count);
    }
    return counts;
  }

  Future<int> getStreakCount() async {
    final db = await database;
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final count = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM tasks WHERE due_date = ? AND is_done = 1',
              [_dateStr(day)])) ??
          0;
      if (count > 0) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
