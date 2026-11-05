import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:discipline/data/database/app_database.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/data/repositories/sqlite_habit_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;
  late SqliteHabitRepository repository;

  setUp(() async {
    // In-memory database for fast, isolated tests
    appDatabase = AppDatabase(inMemory: true);
    await appDatabase.database;
    repository = SqliteHabitRepository(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  group('SqliteHabitRepository Tests', () {
    test('insertHabit and getActiveHabits for daily habit', () async {
      final habit = Habit(
        name: 'Đọc sách 30 phút',
        description: 'Sách phát triển bản thân',
        frequencyType: 'daily',
        reminderEnabled: true,
        reminderHour: 20,
        reminderMinute: 0,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      final inserted = await repository.insertHabit(habit);
      expect(inserted.id, isNotNull);

      final active = await repository.getActiveHabits();
      expect(active.length, equals(1));
      expect(active.first.name, equals('Đọc sách 30 phút'));
      expect(active.first.frequencyType, equals('daily'));
    });

    test('insertHabit with custom days and filter by getHabitsDueOn', () async {
      final customHabit = Habit(
        name: 'Chạy bộ',
        frequencyType: 'custom',
        reminderEnabled: false,
        customDays: [1, 3, 5], // Thứ 2, Thứ 4, Thứ 6
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      await repository.insertHabit(customHabit);

      // 2026-11-06 is Friday (weekday 5) -> Due
      final fridayDue = await repository.getHabitsDueOn(DateTime(2026, 11, 6));
      expect(fridayDue.length, equals(1));
      expect(fridayDue.first.customDays, containsAll([1, 3, 5]));

      // 2026-11-07 is Saturday (weekday 6) -> Not due
      final saturdayDue = await repository.getHabitsDueOn(
        DateTime(2026, 11, 7),
      );
      expect(saturdayDue.isEmpty, isTrue);
    });

    test('updateHabit updates details and custom days atomically', () async {
      final habit = await repository.insertHabit(
        Habit(
          name: 'Học tiếng Anh',
          frequencyType: 'custom',
          reminderEnabled: false,
          customDays: [1, 2],
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        ),
      );

      final updated = habit.copyWith(
        name: 'Học tiếng Anh 45p',
        customDays: [1, 2, 3, 4],
        updatedAt: DateTime(2026, 11, 2),
      );

      await repository.updateHabit(updated);

      final habits = await repository.getActiveHabits();
      expect(habits.first.name, equals('Học tiếng Anh 45p'));
      expect(habits.first.customDays, equals([1, 2, 3, 4]));
    });

    test(
      'archiveHabit marks isArchived = 1 and excludes from active list',
      () async {
        final habit = await repository.insertHabit(
          Habit(
            name: 'Thói quen tạm dừng',
            frequencyType: 'daily',
            reminderEnabled: false,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

        await repository.archiveHabit(habit.id!);

        final active = await repository.getActiveHabits();
        expect(active.isEmpty, isTrue);
      },
    );

    test(
      'toggleCompletion creates and deletes completion record correctly',
      () async {
        final habit = await repository.insertHabit(
          Habit(
            name: 'Uống 2L nước',
            frequencyType: 'daily',
            reminderEnabled: false,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

        // First toggle -> Completed (true)
        final completed = await repository.toggleCompletion(
          habit.id!,
          '2026-11-06',
        );
        expect(completed, isTrue);

        var completions = await repository.getCompletionsForDate('2026-11-06');
        expect(completions.length, equals(1));
        expect(completions.first.habitId, equals(habit.id));

        // Second toggle -> Uncompleted (false)
        final uncompleted = await repository.toggleCompletion(
          habit.id!,
          '2026-11-06',
        );
        expect(uncompleted, isFalse);

        completions = await repository.getCompletionsForDate('2026-11-06');
        expect(completions.isEmpty, isTrue);
      },
    );

    test(
      'unique constraint prevents duplicate completion on same date',
      () async {
        final habit = await repository.insertHabit(
          Habit(
            name: 'Tập yoga',
            frequencyType: 'daily',
            reminderEnabled: false,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

        await repository.toggleCompletion(habit.id!, '2026-11-06');

        // Attempting direct raw insert of duplicate should fail SQLite UNIQUE constraint
        final db = await appDatabase.database;
        expect(
          () async => await db.insert('habit_completions', {
            'habit_id': habit.id,
            'completion_date': '2026-11-06',
            'completed_at': DateTime.now().toIso8601String(),
          }),
          throwsA(isA<DatabaseException>()),
        );
      },
    );

    test('getHabitsForStatistics includes active habits and habits archived during the period', () async {
      final habit = await repository.insertHabit(
        Habit(
          name: 'Thói quen cũ',
          frequencyType: 'daily',
          reminderEnabled: false,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        ),
      );

      await repository.archiveHabit(habit.id!);

      final statsHabits = await repository.getHabitsForStatistics(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 8),
      );

      expect(statsHabits.any((h) => h.id == habit.id), isTrue);
    });
  });
}
