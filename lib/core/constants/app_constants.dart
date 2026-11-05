class AppConstants {
  AppConstants._();

  // Database
  static const String databaseName = 'habit_tracker.db';
  static const int databaseVersion = 1;

  // Tables
  static const String tableHabits = 'habits';
  static const String tableHabitDays = 'habit_days';
  static const String tableHabitCompletions = 'habit_completions';

  // Habit Frequency Types
  static const String frequencyDaily = 'daily';
  static const String frequencyCustom = 'custom';

  // Notification Channel
  static const String notificationChannelId = 'habit_reminders_channel';
  static const String notificationChannelName = 'Habit Reminders';
  static const String notificationChannelDescription =
      'Notifications reminding you to complete your habits';
}
