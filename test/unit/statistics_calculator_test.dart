import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/data/models/habit_completion_model.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/features/statistics/domain/statistics_calculator.dart';

void main() {
  group('StatisticsCalculator Tests', () {
    test('handles division by zero when scheduled occurrences = 0', () {
      final summary = StatisticsCalculator.calculate(
        habits: [],
        completions: [],
        startDate: DateTime(2026, 11, 2),
        endDate: DateTime(2026, 11, 8),
      );

      expect(summary.scheduledOccurrences, equals(0));
      expect(summary.completedOccurrences, equals(0));
      expect(summary.completionRate, equals(0.0));
      expect(summary.hasData, isFalse);
    });

    test('does not count days prior to habit createdAt', () {
      // Habit created on Wednesday 2026-11-04
      final habit = Habit(
        id: 1,
        name: 'Chạy bộ',
        frequencyType: 'daily',
        reminderEnabled: false,
        createdAt: DateTime(2026, 11, 4, 10, 0),
        updatedAt: DateTime(2026, 11, 4, 10, 0),
      );

      // Week runs from Monday 2026-11-02 to Sunday 2026-11-08 (7 days)
      // Since habit created on Wed (Nov 4), only Wed, Thu, Fri, Sat, Sun (5 days) should be scheduled!
      final completions = [
        HabitCompletion(
          habitId: 1,
          completionDate: '2026-11-04',
          completedAt: DateTime(2026, 11, 4, 12, 0),
        ),
        HabitCompletion(
          habitId: 1,
          completionDate: '2026-11-05',
          completedAt: DateTime(2026, 11, 5, 12, 0),
        ),
      ];

      final summary = StatisticsCalculator.calculate(
        habits: [habit],
        completions: completions,
        startDate: DateTime(2026, 11, 2),
        endDate: DateTime(2026, 11, 8),
      );

      expect(summary.scheduledOccurrences, equals(5));
      expect(summary.completedOccurrences, equals(2));
      expect(summary.completionRate, equals(40.0)); // 2 / 5 * 100 = 40.0%
      expect(summary.hasData, isTrue);
    });

    test('counts only scheduled custom weekdays', () {
      // Habit scheduled for Monday (1) and Friday (5)
      final habit = Habit(
        id: 2,
        name: 'Bơi lội',
        frequencyType: 'custom',
        customDays: [1, 5],
        reminderEnabled: false,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      // In the week Nov 2 (Mon) to Nov 8 (Sun), there is 1 Monday and 1 Friday -> 2 scheduled days
      final completions = [
        HabitCompletion(
          habitId: 2,
          completionDate: '2026-11-02', // Monday
          completedAt: DateTime(2026, 11, 2, 8, 0),
        ),
      ];

      final summary = StatisticsCalculator.calculate(
        habits: [habit],
        completions: completions,
        startDate: DateTime(2026, 11, 2),
        endDate: DateTime(2026, 11, 8),
      );

      expect(summary.scheduledOccurrences, equals(2));
      expect(summary.completedOccurrences, equals(1));
      expect(summary.completionRate, equals(50.0));
      expect(summary.habitBreakdown.length, equals(1));
      expect(summary.habitBreakdown.first.habitName, equals('Bơi lội'));
      expect(summary.habitBreakdown.first.completionRate, equals(50.0));
    });
  });
}
