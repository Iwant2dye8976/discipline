import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discipline/app/app.dart';
import 'package:discipline/core/services/notification_service.dart';
import 'package:discipline/data/database/app_database.dart';
import 'package:discipline/data/repositories/habit_repository.dart';
import 'package:discipline/data/repositories/sqlite_habit_repository.dart';
import 'package:discipline/features/habits/presentation/providers/habit_provider.dart';
import 'package:discipline/features/statistics/presentation/providers/statistics_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDatabase = AppDatabase();
  final notificationService = NotificationService();
  await notificationService.init();

  final habitRepository = SqliteHabitRepository(appDatabase);

  runApp(
    MultiProvider(
      providers: [
        Provider<HabitRepository>.value(value: habitRepository),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<HabitProvider>(
          create: (_) => HabitProvider(
            repository: habitRepository,
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => StatisticsProvider(repository: habitRepository),
        ),
      ],
      child: const HabitTrackerApp(),
    ),
  );
}
