import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:discipline/core/constants/app_constants.dart';
import 'package:discipline/data/models/habit_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final timeZoneName = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
        } catch (_) {}
      }

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint(
        'NotificationService init error (e.g. desktop/test environment): $e',
      );
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final androidGranted = await androidPlugin
          ?.requestNotificationsPermission();

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (androidGranted ?? iosGranted) ?? true;
    } catch (e) {
      debugPrint('NotificationService requestPermissions error: $e');
      return false;
    }
  }

  /// Generates a stable, unique 32-bit integer ID for habit reminder on a given weekday
  int generateNotificationId(int habitId, int weekday) {
    return habitId * 100 + weekday;
  }

  /// Returns list of notification IDs configured for this habit
  List<int> getNotificationIdsForHabit(Habit habit) {
    if (!habit.reminderEnabled || habit.id == null) {
      return [];
    }

    if (habit.frequencyType == AppConstants.frequencyDaily) {
      return List.generate(7, (i) => generateNotificationId(habit.id!, i + 1));
    } else {
      return habit.customDays
          .map((day) => generateNotificationId(habit.id!, day))
          .toList();
    }
  }

  /// Schedules repeating weekly notifications for the habit
  Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.id == null) return;

    // First cancel any existing notifications for this habit
    await cancelHabitReminders(habit);

    if (!habit.reminderEnabled ||
        habit.reminderHour == null ||
        habit.reminderMinute == null) {
      return;
    }

    final targetDays = habit.frequencyType == AppConstants.frequencyDaily
        ? [1, 2, 3, 4, 5, 6, 7]
        : habit.customDays;

    for (final day in targetDays) {
      final id = generateNotificationId(habit.id!, day);
      await _scheduleWeeklyReminder(
        id: id,
        habitName: habit.name,
        weekday: day,
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      );
    }
  }

  Future<void> _scheduleWeeklyReminder({
    required int id,
    required String habitName,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    try {
      final notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final scheduledDate = _nextInstanceOfWeekdayTime(weekday, hour, minute);

      await _notificationsPlugin.zonedSchedule(
        id,
        'Nhắc nhở thói quen: $habitName',
        'Đã đến giờ thực hiện "$habitName". Hãy hoàn thành ngay nhé!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification $id: $e');
    }
  }

  /// Cancels all possible notification IDs for a habit (all 7 weekdays)
  Future<void> cancelHabitReminders(Habit habit) async {
    if (habit.id == null) return;
    await cancelHabitRemindersById(habit.id!);
  }

  Future<void> cancelHabitRemindersById(int habitId) async {
    try {
      for (int day = 1; day <= 7; day++) {
        final id = generateNotificationId(habitId, day);
        await _notificationsPlugin.cancel(id);
      }
    } catch (e) {
      debugPrint('Failed to cancel notifications for habit $habitId: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
