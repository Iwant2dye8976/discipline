import 'package:discipline/core/constants/app_constants.dart';
import 'package:discipline/core/utils/date_time_utils.dart';
import 'package:discipline/data/models/habit_completion_model.dart';
import 'package:discipline/data/models/habit_model.dart';

class HabitStatItem {
  final int habitId;
  final String habitName;
  final int scheduledOccurrences;
  final int completedOccurrences;
  final double completionRate;

  const HabitStatItem({
    required this.habitId,
    required this.habitName,
    required this.scheduledOccurrences,
    required this.completedOccurrences,
    required this.completionRate,
  });
}

class StatisticsSummary {
  final int scheduledOccurrences;
  final int completedOccurrences;
  final double completionRate;
  final Map<String, int> dailyCompletedCounts;
  final List<HabitStatItem> habitBreakdown;

  const StatisticsSummary({
    required this.scheduledOccurrences,
    required this.completedOccurrences,
    required this.completionRate,
    required this.dailyCompletedCounts,
    required this.habitBreakdown,
  });

  bool get hasData => scheduledOccurrences > 0;
}

class StatisticsCalculator {
  StatisticsCalculator._();

  static StatisticsSummary calculate({
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    final habitScheduled = <int, int>{};
    final habitCompleted = <int, int>{};
    final dailyCompletedCounts = <String, int>{};

    for (final habit in habits) {
      if (habit.id != null) {
        habitScheduled[habit.id!] = 0;
        habitCompleted[habit.id!] = 0;
      }
    }

    // 1. Calculate scheduled occurrences day by day
    var currentDay = start;
    while (!currentDay.isAfter(end)) {
      final dateStr = DateTimeUtils.formatDate(currentDay);
      dailyCompletedCounts[dateStr] = 0;

      for (final habit in habits) {
        if (habit.id == null) continue;

        final createdDate = DateTime(
          habit.createdAt.year,
          habit.createdAt.month,
          habit.createdAt.day,
        );

        // Do not count days before habit was created
        if (currentDay.isBefore(createdDate)) {
          continue;
        }

        // Check if habit is scheduled for this weekday
        final isScheduled =
            habit.frequencyType == AppConstants.frequencyDaily ||
            habit.customDays.contains(currentDay.weekday);

        if (isScheduled) {
          habitScheduled[habit.id!] = (habitScheduled[habit.id!] ?? 0) + 1;
        }
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }

    // 2. Count completions
    final validHabitIds = habits.map((h) => h.id).whereType<int>().toSet();

    for (final completion in completions) {
      if (!validHabitIds.contains(completion.habitId)) continue;

      final completionDate = DateTimeUtils.parseDate(completion.completionDate);
      if (completionDate.isBefore(start) || completionDate.isAfter(end)) {
        continue;
      }

      final dateStr = completion.completionDate;
      dailyCompletedCounts[dateStr] = (dailyCompletedCounts[dateStr] ?? 0) + 1;

      habitCompleted[completion.habitId] =
          (habitCompleted[completion.habitId] ?? 0) + 1;
    }

    // 3. Totals and individual breakdowns
    int totalScheduled = 0;
    int totalCompleted = 0;
    final breakdown = <HabitStatItem>[];

    for (final habit in habits) {
      if (habit.id == null) continue;
      final scheduled = habitScheduled[habit.id!] ?? 0;
      final completed = habitCompleted[habit.id!] ?? 0;

      totalScheduled += scheduled;
      totalCompleted += completed;

      final rate = scheduled == 0 ? 0.0 : (completed / scheduled) * 100.0;
      breakdown.add(
        HabitStatItem(
          habitId: habit.id!,
          habitName: habit.name,
          scheduledOccurrences: scheduled,
          completedOccurrences: completed,
          completionRate: rate,
        ),
      );
    }

    final overallRate = totalScheduled == 0
        ? 0.0
        : (totalCompleted / totalScheduled) * 100.0;

    return StatisticsSummary(
      scheduledOccurrences: totalScheduled,
      completedOccurrences: totalCompleted,
      completionRate: overallRate,
      dailyCompletedCounts: dailyCompletedCounts,
      habitBreakdown: breakdown,
    );
  }
}
