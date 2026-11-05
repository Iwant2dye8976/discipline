import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/features/statistics/presentation/providers/statistics_provider.dart';

import 'habit_provider_test.dart';

void main() {
  late FakeHabitRepository repository;
  late StatisticsProvider provider;

  setUp(() {
    repository = FakeHabitRepository();
    provider = StatisticsProvider(repository: repository);
  });

  group('StatisticsProvider Review Fix Tests', () {
    test('month navigation does not overflow on 31st of month', () {
      provider.setPeriod(StatisticsPeriod.month);
      // Set to March 31
      provider.setReferenceDate(DateTime(2026, 3, 31));

      // Previous month should be February (month 2)
      provider.previousPeriod();
      expect(provider.referenceDate.month, equals(2));
      expect(provider.referenceDate.year, equals(2026));

      // Reset to January 31
      provider.setReferenceDate(DateTime(2026, 1, 31));

      // Next month should be February (month 2)
      provider.nextPeriod();
      expect(provider.referenceDate.month, equals(2));
      expect(provider.referenceDate.year, equals(2026));
    });

    test(
      'statistics includes archived habits that existed during the period',
      () async {
        // Habit created Nov 1, completed Nov 2, then archived Nov 3
        final habit = await repository.insertHabit(
          Habit(
            name: 'Thói quen đã lưu trữ',
            frequencyType: 'daily',
            reminderEnabled: false,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

        await repository.toggleCompletion(habit.id!, '2026-11-02');
        // Archive on Nov 3 (after the period started Nov 2)
        final idx = repository.habits.indexWhere((h) => h.id == habit.id);
        repository.habits[idx] = repository.habits[idx].copyWith(
          isArchived: true,
          updatedAt: DateTime(2026, 11, 3),
        );

        // Week from Nov 2 to Nov 8
        provider.setPeriod(StatisticsPeriod.week);
        provider.setReferenceDate(DateTime(2026, 11, 4));

        await provider.loadStatistics();

        // Summary should include this habit and its completion
        expect(provider.summary, isNotNull);
        expect(provider.summary!.completedOccurrences, equals(1));
        expect(
          provider.summary!.habitBreakdown.any(
            (h) => h.habitName == 'Thói quen đã lưu trữ',
          ),
          isTrue,
        );
      },
    );
  });
}
