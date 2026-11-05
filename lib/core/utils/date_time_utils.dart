import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Formats date to `YYYY-MM-DD`
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Parses `YYYY-MM-DD` into DateTime at 00:00:00 local time
  static DateTime parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Gets start of week (Monday 00:00:00)
  static DateTime getStartOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysToSubtract, 0, 0, 0);
  }

  /// Gets end of week (Sunday 23:59:59)
  static DateTime getEndOfWeek(DateTime date) {
    final daysToAdd = DateTime.sunday - date.weekday;
    return DateTime(date.year, date.month, date.day + daysToAdd, 23, 59, 59);
  }

  /// Gets start of month (Day 1, 00:00:00)
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1, 0, 0, 0);
  }

  /// Gets end of month (Last day, 23:59:59)
  static DateTime getEndOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    return DateTime(
      lastDayOfMonth.year,
      lastDayOfMonth.month,
      lastDayOfMonth.day,
      23,
      59,
      59,
    );
  }

  /// Gets Vietnamese weekday name: 1 -> Thứ 2, ..., 7 -> Chủ Nhật
  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  /// Determines whether a habit is due on a specific date based on frequency and custom days
  static bool isHabitDueOn(
    DateTime date,
    String frequencyType,
    List<int> customDays,
  ) {
    if (frequencyType == 'daily') {
      return true;
    }
    return customDays.contains(date.weekday);
  }
}
