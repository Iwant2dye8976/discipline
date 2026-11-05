import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:discipline/app/app.dart';
import 'package:discipline/core/services/notification_service.dart';
import 'package:discipline/data/repositories/habit_repository.dart';
import 'package:discipline/features/habits/presentation/providers/habit_provider.dart';
import 'package:discipline/features/statistics/presentation/providers/statistics_provider.dart';

import 'unit/habit_provider_test.dart';

void main() {
  testWidgets('App smoke test: boots and navigates between tabs', (
    WidgetTester tester,
  ) async {
    final repository = FakeHabitRepository();
    final notificationService = FakeNotificationService();

    final habitProvider = HabitProvider(
      repository: repository,
      notificationService: notificationService,
    );
    final statisticsProvider = StatisticsProvider(repository: repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<HabitRepository>.value(value: repository),
          Provider<NotificationService>.value(value: notificationService),
          ChangeNotifierProvider<HabitProvider>.value(value: habitProvider),
          ChangeNotifierProvider<StatisticsProvider>.value(
            value: statisticsProvider,
          ),
        ],
        child: const HabitTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Habit List screen is initially displayed
    expect(find.text('Thói quen của tôi'), findsOneWidget);
    expect(find.text('Thói quen'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);

    // Switch to Statistics tab
    await tester.tap(find.text('Thống kê'));
    await tester.pumpAndSettle();

    expect(find.text('Thống kê tiến độ'), findsOneWidget);

    // Switch back to Habit tab
    await tester.tap(find.text('Thói quen'));
    await tester.pumpAndSettle();

    expect(find.text('Thói quen của tôi'), findsOneWidget);
  });
}
