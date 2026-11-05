import 'package:flutter_test/flutter_test.dart';
import 'package:discipline/core/services/notification_service.dart';
import 'package:discipline/data/models/habit_model.dart';

void main() {
  late NotificationService notificationService;

  setUp(() {
    notificationService = NotificationService();
  });

  group('NotificationService Tests', () {
    test('generateNotificationId produces distinct deterministic IDs for habit and weekday', () {
      final id1 = notificationService.generateNotificationId(10, 1);
      final id2 = notificationService.generateNotificationId(10, 2);
      final id3 = notificationService.generateNotificationId(11, 1);

      expect(id1, equals(1001));
      expect(id2, equals(1002));
      expect(id3, equals(1101));
      expect(id1, isNot(equals(id2)));
      expect(id1, isNot(equals(id3)));
    });

    test(
      'getNotificationIdsForHabit returns correct list of IDs for daily habit',
      () {
        final habit = Habit(
          id: 5,
          name: 'Đọc sách',
          frequencyType: 'daily',
          reminderEnabled: true,
          reminderHour: 9,
          reminderMinute: 0,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        );

        final ids = notificationService.getNotificationIdsForHabit(habit);
        // Daily habit scheduled for days 1 through 7
        expect(ids.length, equals(7));
        expect(ids, containsAll([501, 502, 503, 504, 505, 506, 507]));
      },
    );

    test(
      'getNotificationIdsForHabit returns correct IDs for custom weekday habit',
      () {
        final habit = Habit(
          id: 7,
          name: 'Tập gym',
          frequencyType: 'custom',
          reminderEnabled: true,
          reminderHour: 17,
          reminderMinute: 30,
          customDays: [2, 4, 6], // Tue, Thu, Sat
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        );

        final ids = notificationService.getNotificationIdsForHabit(habit);
        expect(ids.length, equals(3));
        expect(ids, containsAll([702, 704, 706]));
      },
    );

    test('getNotificationIdsForHabit returns empty list if reminder is disabled or id is null', () {
      final habitWithoutReminder = Habit(
        id: 8,
        name: 'Uống nước',
        frequencyType: 'daily',
        reminderEnabled: false,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      expect(
        notificationService.getNotificationIdsForHabit(habitWithoutReminder),
        isEmpty,
      );

      final habitWithoutId = Habit(
        name: 'Thói quen mới',
        frequencyType: 'daily',
        reminderEnabled: true,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      expect(
        notificationService.getNotificationIdsForHabit(habitWithoutId),
        isEmpty,
      );
    });
  });
}
