import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils Tests', () {
    test('formatDate should format DateTime to YYYY-MM-DD string', () {
      final date = DateTime(2026, 11, 6, 15, 30);
      expect(DateTimeUtils.formatDate(date), equals('2026-11-06'));
    });

    test(
      'parseDate should parse YYYY-MM-DD string to DateTime at start of day',
      () {
        final parsed = DateTimeUtils.parseDate('2026-11-06');
        expect(parsed.year, equals(2026));
        expect(parsed.month, equals(11));
        expect(parsed.day, equals(6));
        expect(parsed.hour, equals(0));
        expect(parsed.minute, equals(0));
      },
    );

    test(
      'getStartOfWeek should return Monday 00:00:00 for any day in that week',
      () {
        // 2026-11-06 is a Friday (weekday 5)
        final friday = DateTime(2026, 11, 6, 14, 20);
        final startOfWeek = DateTimeUtils.getStartOfWeek(friday);

        expect(startOfWeek.weekday, equals(DateTime.monday));
        expect(DateTimeUtils.formatDate(startOfWeek), equals('2026-11-02'));
        expect(startOfWeek.hour, equals(0));
        expect(startOfWeek.minute, equals(0));
        expect(startOfWeek.second, equals(0));
      },
    );

    test(
      'getEndOfWeek should return Sunday 23:59:59 for any day in that week',
      () {
        final friday = DateTime(2026, 11, 6, 14, 20);
        final endOfWeek = DateTimeUtils.getEndOfWeek(friday);

        expect(endOfWeek.weekday, equals(DateTime.sunday));
        expect(DateTimeUtils.formatDate(endOfWeek), equals('2026-11-08'));
        expect(endOfWeek.hour, equals(23));
        expect(endOfWeek.minute, equals(59));
        expect(endOfWeek.second, equals(59));
      },
    );

    test(
      'getStartOfMonth and getEndOfMonth should return correct boundaries',
      () {
        final date = DateTime(2026, 11, 6);
        final start = DateTimeUtils.getStartOfMonth(date);
        final end = DateTimeUtils.getEndOfMonth(date);

        expect(DateTimeUtils.formatDate(start), equals('2026-11-01'));
        expect(DateTimeUtils.formatDate(end), equals('2026-11-30'));
      },
    );

    test('getWeekdayName should return correct Vietnamese weekday label', () {
      expect(DateTimeUtils.getWeekdayName(1), equals('Thứ 2'));
      expect(DateTimeUtils.getWeekdayName(2), equals('Thứ 3'));
      expect(DateTimeUtils.getWeekdayName(3), equals('Thứ 4'));
      expect(DateTimeUtils.getWeekdayName(4), equals('Thứ 5'));
      expect(DateTimeUtils.getWeekdayName(5), equals('Thứ 6'));
      expect(DateTimeUtils.getWeekdayName(6), equals('Thứ 7'));
      expect(DateTimeUtils.getWeekdayName(7), equals('Chủ Nhật'));
    });

    test(
      'isHabitDueOn correctly determines if habit is due on a given date',
      () {
        // Friday: weekday 5
        final friday = DateTime(2026, 11, 6);
        expect(DateTimeUtils.isHabitDueOn(friday, 'daily', []), isTrue);
        expect(DateTimeUtils.isHabitDueOn(friday, 'custom', [1, 3, 5]), isTrue);
        expect(
          DateTimeUtils.isHabitDueOn(friday, 'custom', [1, 2, 3]),
          isFalse,
        );
      },
    );
  });
}
