import 'package:sqflite/sqflite.dart';
import 'package:discipline/core/constants/app_constants.dart';
import 'package:discipline/core/utils/date_time_utils.dart';
import 'package:discipline/data/database/app_database.dart';
import 'package:discipline/data/models/habit_completion_model.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/data/repositories/habit_repository.dart';

class SqliteHabitRepository implements HabitRepository {
  final AppDatabase appDatabase;

  SqliteHabitRepository(this.appDatabase);

  @override
  Future<List<Habit>> getActiveHabits() async {
    final db = await appDatabase.database;
    final habitMaps = await db.query(
      AppConstants.tableHabits,
      where: 'is_archived = 0',
      orderBy: 'created_at ASC',
    );

    final habits = <Habit>[];
    for (final map in habitMaps) {
      final habitId = map['id'] as int;
      final days = await _getCustomDays(db, habitId);
      habits.add(Habit.fromMap(map, customDays: days));
    }
    return habits;
  }

  @override
  Future<List<Habit>> getHabitsDueOn(DateTime date) async {
    final activeHabits = await getActiveHabits();
    return activeHabits.where((habit) {
      return DateTimeUtils.isHabitDueOn(
        date,
        habit.frequencyType,
        habit.customDays,
      );
    }).toList();
  }

  @override
  Future<Habit> insertHabit(Habit habit) async {
    final db = await appDatabase.database;
    return await db.transaction((txn) async {
      final habitId = await txn.insert(
        AppConstants.tableHabits,
        habit.toMap()..remove('id'),
      );

      if (habit.frequencyType == AppConstants.frequencyCustom &&
          habit.customDays.isNotEmpty) {
        final batch = txn.batch();
        for (final weekday in habit.customDays) {
          batch.insert(AppConstants.tableHabitDays, {
            'habit_id': habitId,
            'weekday': weekday,
          });
        }
        await batch.commit(noResult: true);
      }

      return habit.copyWith(id: habitId);
    });
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    if (habit.id == null) return;
    final db = await appDatabase.database;

    await db.transaction((txn) async {
      await txn.update(
        AppConstants.tableHabits,
        habit.toMap(),
        where: 'id = ?',
        whereArgs: [habit.id],
      );

      // Replace custom days
      await txn.delete(
        AppConstants.tableHabitDays,
        where: 'habit_id = ?',
        whereArgs: [habit.id],
      );

      if (habit.frequencyType == AppConstants.frequencyCustom &&
          habit.customDays.isNotEmpty) {
        final batch = txn.batch();
        for (final weekday in habit.customDays) {
          batch.insert(AppConstants.tableHabitDays, {
            'habit_id': habit.id,
            'weekday': weekday,
          });
        }
        await batch.commit(noResult: true);
      }
    });
  }

  @override
  Future<void> archiveHabit(int habitId) async {
    final db = await appDatabase.database;
    await db.update(
      AppConstants.tableHabits,
      {'is_archived': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  @override
  Future<void> deleteHabit(int habitId) async {
    final db = await appDatabase.database;
    await db.delete(
      AppConstants.tableHabits,
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  @override
  Future<bool> toggleCompletion(int habitId, String completionDate) async {
    final db = await appDatabase.database;
    final existing = await db.query(
      AppConstants.tableHabitCompletions,
      where: 'habit_id = ? AND completion_date = ?',
      whereArgs: [habitId, completionDate],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Remove completion
      await db.delete(
        AppConstants.tableHabitCompletions,
        where: 'habit_id = ? AND completion_date = ?',
        whereArgs: [habitId, completionDate],
      );
      return false;
    } else {
      // Add completion
      await db.insert(AppConstants.tableHabitCompletions, {
        'habit_id': habitId,
        'completion_date': completionDate,
        'completed_at': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForDate(
    String completionDate,
  ) async {
    final db = await appDatabase.database;
    final maps = await db.query(
      AppConstants.tableHabitCompletions,
      where: 'completion_date = ?',
      whereArgs: [completionDate],
    );
    return maps.map((m) => HabitCompletion.fromMap(m)).toList();
  }

  @override
  Future<List<HabitCompletion>> getCompletionsInRange(
    String startDate,
    String endDate,
  ) async {
    final db = await appDatabase.database;
    final maps = await db.query(
      AppConstants.tableHabitCompletions,
      where: 'completion_date >= ? AND completion_date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'completion_date ASC',
    );
    return maps.map((m) => HabitCompletion.fromMap(m)).toList();
  }

  @override
  Future<List<Habit>> getHabitsForStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await appDatabase.database;
    final endIso = '${DateTimeUtils.formatDate(endDate)}T23:59:59.999';
    final startIso = '${DateTimeUtils.formatDate(startDate)}T00:00:00.000';

    final habitMaps = await db.query(
      AppConstants.tableHabits,
      where: 'created_at <= ? AND (is_archived = 0 OR updated_at >= ?)',
      whereArgs: [endIso, startIso],
      orderBy: 'created_at ASC',
    );

    final habits = <Habit>[];
    for (final map in habitMaps) {
      final habitId = map['id'] as int;
      final days = await _getCustomDays(db, habitId);
      habits.add(Habit.fromMap(map, customDays: days));
    }
    return habits;
  }

  Future<List<int>> _getCustomDays(DatabaseExecutor db, int habitId) async {
    final dayMaps = await db.query(
      AppConstants.tableHabitDays,
      columns: ['weekday'],
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'weekday ASC',
    );
    return dayMaps.map((m) => m['weekday'] as int).toList();
  }
}
