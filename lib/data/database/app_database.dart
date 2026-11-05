import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:discipline/core/constants/app_constants.dart';

class AppDatabase {
  final bool inMemory;
  Database? _db;

  AppDatabase({this.inMemory = false});

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (inMemory) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: AppConstants.databaseVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableHabits} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        frequency_type TEXT NOT NULL,
        reminder_enabled INTEGER NOT NULL,
        reminder_hour INTEGER,
        reminder_minute INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableHabitDays} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        weekday INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES ${AppConstants.tableHabits} (id) ON DELETE CASCADE,
        UNIQUE (habit_id, weekday)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableHabitCompletions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        completion_date TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES ${AppConstants.tableHabits} (id) ON DELETE CASCADE,
        UNIQUE (habit_id, completion_date)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_completions_date ON ${AppConstants.tableHabitCompletions} (completion_date)',
    );
    await db.execute(
      'CREATE INDEX idx_completions_habit_date ON ${AppConstants.tableHabitCompletions} (habit_id, completion_date)',
    );
    await db.execute(
      'CREATE INDEX idx_habit_days_habit_id ON ${AppConstants.tableHabitDays} (habit_id)',
    );
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
