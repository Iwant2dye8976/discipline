import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/data/models/habit_completion_model.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/data/repositories/habit_repository.dart';
import 'package:discipline/core/services/notification_service.dart';
import 'package:discipline/features/habits/presentation/providers/habit_provider.dart';

class FakeHabitRepository implements HabitRepository {
  final List<Habit> habits = [];
  final Set<String> completions = {}; // "habitId_dateStr"
  bool shouldThrowOnToggle = false;

  @override
  Future<List<Habit>> getActiveHabits() async {
    return habits.where((h) => !h.isArchived).toList();
  }

  @override
  Future<List<Habit>> getHabitsDueOn(DateTime date) async {
    return habits.where((h) {
      if (h.isArchived) return false;
      if (h.frequencyType == 'daily') return true;
      return h.customDays.contains(date.weekday);
    }).toList();
  }

  @override
  Future<Habit> insertHabit(Habit habit) async {
    final newHabit = habit.copyWith(id: habits.length + 1);
    habits.add(newHabit);
    return newHabit;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final idx = habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) {
      habits[idx] = habit;
    }
  }

  @override
  Future<void> archiveHabit(int habitId) async {
    final idx = habits.indexWhere((h) => h.id == habitId);
    if (idx != -1) {
      habits[idx] = habits[idx].copyWith(
        isArchived: true,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteHabit(int habitId) async {
    habits.removeWhere((h) => h.id == habitId);
  }

  @override
  Future<bool> toggleCompletion(int habitId, String completionDate) async {
    if (shouldThrowOnToggle) {
      throw Exception('DB toggle error');
    }
    final key = '${habitId}_$completionDate';
    if (completions.contains(key)) {
      completions.remove(key);
      return false;
    } else {
      completions.add(key);
      return true;
    }
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForDate(
    String completionDate,
  ) async {
    return completions
        .where((k) => k.endsWith('_$completionDate'))
        .map(
          (k) => HabitCompletion(
            habitId: int.parse(k.split('_')[0]),
            completionDate: completionDate,
            completedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<List<HabitCompletion>> getCompletionsInRange(
    String startDate,
    String endDate,
  ) async {
    return completions
        .where((k) {
          final date = k.split('_')[1];
          return date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0;
        })
        .map(
          (k) => HabitCompletion(
            habitId: int.parse(k.split('_')[0]),
            completionDate: k.split('_')[1],
            completedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<List<Habit>> getHabitsForStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return habits.where((h) {
      if (h.createdAt.isAfter(endDate)) return false;
      if (!h.isArchived) return true;
      return !h.updatedAt.isBefore(startDate);
    }).toList();
  }
}

class FakeNotificationService extends NotificationService {
  int scheduledCount = 0;
  int cancelledCount = 0;
  int requestedPermissionsCount = 0;

  @override
  Future<bool> requestPermissions() async {
    requestedPermissionsCount++;
    return true;
  }

  @override
  Future<void> scheduleHabitReminder(Habit habit) async {
    scheduledCount++;
  }

  @override
  Future<void> cancelHabitReminders(Habit habit) async {
    cancelledCount++;
  }

  @override
  Future<void> cancelHabitRemindersById(int habitId) async {
    cancelledCount++;
  }
}

void main() {
  late FakeHabitRepository repository;
  late FakeNotificationService notificationService;
  late HabitProvider provider;

  setUp(() {
    repository = FakeHabitRepository();
    notificationService = FakeNotificationService();
    provider = HabitProvider(
      repository: repository,
      notificationService: notificationService,
    );
  });

  group('HabitProvider Tests', () {
    test(
      'loadHabitsForDate loads due habits, active habits, and progress',
      () async {
        final habit1 = Habit(
          name: 'Đọc sách',
          frequencyType: 'daily',
          reminderEnabled: false,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        );
        final habit2 = Habit(
          name: 'Chạy bộ',
          frequencyType: 'custom',
          customDays: [1, 3], // Mon, Wed
          reminderEnabled: false,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        );

        await repository.insertHabit(habit1);
        await repository.insertHabit(habit2);

        // 2026-11-06 is Friday (weekday 5) -> Only habit1 is due
        await provider.loadHabitsForDate(DateTime(2026, 11, 6));

        expect(provider.allHabits.length, equals(2));
        expect(provider.dueHabits.length, equals(1));
        expect(provider.dueHabits.first.name, equals('Đọc sách'));
        expect(provider.totalDueCount, equals(1));
        expect(provider.completedCount, equals(0));
        expect(provider.todayProgress, equals(0.0));
      },
    );

    test('toggleCompletion updates state optimistically and tracks completion count', () async {
      final habit = await repository.insertHabit(
        Habit(
          name: 'Uống nước',
          frequencyType: 'daily',
          reminderEnabled: false,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        ),
      );

      await provider.loadHabitsForDate(DateTime(2026, 11, 6));
      expect(provider.completedHabitIds.contains(habit.id), isFalse);

      await provider.toggleCompletion(habit.id!);

      expect(provider.completedHabitIds.contains(habit.id), isTrue);
      expect(provider.completedCount, equals(1));
      expect(provider.todayProgress, equals(1.0));
      expect(provider.isAllTodayCompleted, isTrue);

      // Untoggle
      await provider.toggleCompletion(habit.id!);
      expect(provider.completedHabitIds.contains(habit.id), isFalse);
      expect(provider.completedCount, equals(0));
      expect(provider.todayProgress, equals(0.0));
    });

    test('toggleCompletion rolls back state and sets error message if repository fails', () async {
      final habit = await repository.insertHabit(
        Habit(
          name: 'Tập gym',
          frequencyType: 'daily',
          reminderEnabled: false,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        ),
      );

      await provider.loadHabitsForDate(DateTime(2026, 11, 6));
      repository.shouldThrowOnToggle = true;

      await provider.toggleCompletion(habit.id!);

      // Should rollback to not completed
      expect(provider.completedHabitIds.contains(habit.id), isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('addHabit schedules reminder and refreshes habits', () async {
      final habit = Habit(
        name: 'Thiền định',
        frequencyType: 'daily',
        reminderEnabled: true,
        reminderHour: 6,
        reminderMinute: 0,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      final success = await provider.addHabit(habit);
      expect(success, isTrue);
      expect(notificationService.scheduledCount, equals(1));
      expect(provider.allHabits.length, equals(1));
    });

    test(
      'archiveHabit cancels reminder and removes from active list',
      () async {
        final habit = await repository.insertHabit(
          Habit(
            name: 'Thói quen cũ',
            frequencyType: 'daily',
            reminderEnabled: true,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

        await provider.loadHabitsForDate(DateTime(2026, 11, 6));
        await provider.archiveHabit(habit.id!);

        expect(notificationService.cancelledCount, greaterThan(0));
        expect(provider.allHabits.isEmpty, isTrue);
      },
    );
  });
}
