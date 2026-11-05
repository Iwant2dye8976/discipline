import 'package:discipline/data/models/habit_completion_model.dart';
import 'package:discipline/data/models/habit_model.dart';

abstract class HabitRepository {
  Future<List<Habit>> getActiveHabits();
  Future<List<Habit>> getHabitsDueOn(DateTime date);
  Future<Habit> insertHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> archiveHabit(int habitId);
  Future<void> deleteHabit(int habitId);
  Future<bool> toggleCompletion(int habitId, String completionDate);
  Future<List<HabitCompletion>> getCompletionsForDate(String completionDate);
  Future<List<HabitCompletion>> getCompletionsInRange(
    String startDate,
    String endDate,
  );
  Future<List<Habit>> getHabitsForStatistics(
    DateTime startDate,
    DateTime endDate,
  );
}
