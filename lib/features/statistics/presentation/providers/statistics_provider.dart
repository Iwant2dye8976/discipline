import 'package:flutter/foundation.dart';
import 'package:discipline/core/utils/date_time_utils.dart';
import 'package:discipline/data/repositories/habit_repository.dart';
import 'package:discipline/features/statistics/domain/statistics_calculator.dart';

enum StatisticsPeriod { day, week, month }

class StatisticsProvider extends ChangeNotifier {
  final HabitRepository repository;

  StatisticsPeriod _selectedPeriod = StatisticsPeriod.week;
  DateTime _referenceDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  StatisticsSummary? _summary;

  StatisticsProvider({required this.repository});

  StatisticsPeriod get selectedPeriod => _selectedPeriod;
  DateTime get referenceDate => _referenceDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StatisticsSummary? get summary => _summary;

  DateTime get startDate {
    switch (_selectedPeriod) {
      case StatisticsPeriod.day:
        return DateTime(
          _referenceDate.year,
          _referenceDate.month,
          _referenceDate.day,
        );
      case StatisticsPeriod.week:
        return DateTimeUtils.getStartOfWeek(_referenceDate);
      case StatisticsPeriod.month:
        return DateTimeUtils.getStartOfMonth(_referenceDate);
    }
  }

  DateTime get endDate {
    switch (_selectedPeriod) {
      case StatisticsPeriod.day:
        return DateTime(
          _referenceDate.year,
          _referenceDate.month,
          _referenceDate.day,
          23,
          59,
          59,
        );
      case StatisticsPeriod.week:
        return DateTimeUtils.getEndOfWeek(_referenceDate);
      case StatisticsPeriod.month:
        return DateTimeUtils.getEndOfMonth(_referenceDate);
    }
  }

  void setPeriod(StatisticsPeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      loadStatistics();
    }
  }

  void setReferenceDate(DateTime date) {
    _referenceDate = date;
    loadStatistics();
  }

  void previousPeriod() {
    switch (_selectedPeriod) {
      case StatisticsPeriod.day:
        _referenceDate = _referenceDate.subtract(const Duration(days: 1));
        break;
      case StatisticsPeriod.week:
        _referenceDate = _referenceDate.subtract(const Duration(days: 7));
        break;
      case StatisticsPeriod.month:
        _referenceDate = DateTime(
          _referenceDate.year,
          _referenceDate.month - 1,
          1,
        );
        break;
    }
    loadStatistics();
  }

  void nextPeriod() {
    switch (_selectedPeriod) {
      case StatisticsPeriod.day:
        _referenceDate = _referenceDate.add(const Duration(days: 1));
        break;
      case StatisticsPeriod.week:
        _referenceDate = _referenceDate.add(const Duration(days: 7));
        break;
      case StatisticsPeriod.month:
        _referenceDate = DateTime(
          _referenceDate.year,
          _referenceDate.month + 1,
          1,
        );
        break;
    }
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final start = startDate;
      final end = endDate;
      final startStr = DateTimeUtils.formatDate(start);
      final endStr = DateTimeUtils.formatDate(end);

      final habits = await repository.getHabitsForStatistics(start, end);
      final completions = await repository.getCompletionsInRange(
        startStr,
        endStr,
      );

      _summary = StatisticsCalculator.calculate(
        habits: habits,
        completions: completions,
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      _errorMessage = 'Không thể tính toán thống kê: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
