import 'package:flutter/foundation.dart';
import 'package:discipline/core/services/notification_service.dart';
import 'package:discipline/core/utils/date_time_utils.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/data/repositories/habit_repository.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository repository;
  final NotificationService notificationService;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  List<Habit> _dueHabits = [];
  List<Habit> _allHabits = [];
  Set<int> _completedHabitIds = {};

  HabitProvider({required this.repository, required this.notificationService});

  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Habit> get dueHabits => List.unmodifiable(_dueHabits);
  List<Habit> get allHabits => List.unmodifiable(_allHabits);
  Set<int> get completedHabitIds => Set.unmodifiable(_completedHabitIds);

  int get completedCount =>
      _dueHabits.where((h) => _completedHabitIds.contains(h.id)).length;

  int get totalDueCount => _dueHabits.length;

  double get todayProgress =>
      totalDueCount == 0 ? 0.0 : completedCount / totalDueCount;

  bool get isAllTodayCompleted =>
      totalDueCount > 0 && completedCount == totalDueCount;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadHabitsForDate(date);
  }

  Future<void> loadHabitsForDate(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dateStr = DateTimeUtils.formatDate(date);
      final active = await repository.getActiveHabits();
      final due = await repository.getHabitsDueOn(date);
      final completions = await repository.getCompletionsForDate(dateStr);

      _allHabits = active;
      _dueHabits = due;
      _completedHabitIds = completions.map((c) => c.habitId).toSet();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách thói quen: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHabit(Habit habit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final inserted = await repository.insertHabit(habit);
      if (inserted.reminderEnabled) {
        await notificationService.scheduleHabitReminder(inserted);
      }
      await loadHabitsForDate(_selectedDate);
      return true;
    } catch (e) {
      _errorMessage = 'Thêm thói quen thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHabit(Habit habit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.updateHabit(habit);
      if (habit.reminderEnabled) {
        await notificationService.scheduleHabitReminder(habit);
      } else {
        await notificationService.cancelHabitReminders(habit);
      }
      await loadHabitsForDate(_selectedDate);
      return true;
    } catch (e) {
      _errorMessage = 'Cập nhật thói quen thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveHabit(int habitId) async {
    _errorMessage = null;
    try {
      await repository.archiveHabit(habitId);
      await notificationService.cancelHabitRemindersById(habitId);
      await loadHabitsForDate(_selectedDate);
      return true;
    } catch (e) {
      _errorMessage = 'Lưu trữ thói quen thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggles habit completion with optimistic update and rollback on failure
  Future<void> toggleCompletion(int habitId) async {
    final dateStr = DateTimeUtils.formatDate(_selectedDate);
    final isCurrentlyCompleted = _completedHabitIds.contains(habitId);

    // 1. Optimistic update
    if (isCurrentlyCompleted) {
      _completedHabitIds.remove(habitId);
    } else {
      _completedHabitIds.add(habitId);
    }
    notifyListeners();

    // 2. Perform DB operation
    try {
      final result = await repository.toggleCompletion(habitId, dateStr);

      // Verify DB result matches our optimistic expectation
      if (result != !isCurrentlyCompleted) {
        // Correct if out of sync
        if (result) {
          _completedHabitIds.add(habitId);
        } else {
          _completedHabitIds.remove(habitId);
        }
        notifyListeners();
      }
    } catch (e) {
      // 3. Rollback on failure
      if (isCurrentlyCompleted) {
        _completedHabitIds.add(habitId);
      } else {
        _completedHabitIds.remove(habitId);
      }
      _errorMessage = 'Không thể cập nhật trạng thái thói quen: $e';
      notifyListeners();
    }
  }
}
