import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:discipline/features/statistics/presentation/screens/statistics_screen.dart';

import '../unit/habit_provider_test.dart';

void main() {
  late FakeHabitRepository repository;
  late StatisticsProvider provider;

  setUp(() {
    repository = FakeHabitRepository();
    provider = StatisticsProvider(repository: repository);
  });

  Widget buildTestableWidget() {
    return ChangeNotifierProvider<StatisticsProvider>.value(
      value: provider,
      child: const MaterialApp(home: StatisticsScreen()),
    );
  }

  group('StatisticsScreen Widget Tests', () {
    testWidgets('displays empty state when there are no scheduled habits', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Chưa có dữ liệu'), findsOneWidget);
      expect(find.text('Ngày'), findsOneWidget);
      expect(find.text('Tuần'), findsOneWidget);
      expect(find.text('Tháng'), findsOneWidget);
    });

    testWidgets('displays metric cards and habit breakdown when habits exist', (
      tester,
    ) async {
      final habit = await repository.insertHabit(
        Habit(
          name: 'Đọc sách mỗi ngày',
          frequencyType: 'daily',
          reminderEnabled: false,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        ),
      );

      await repository.toggleCompletion(habit.id!, '2026-11-06');

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Hoàn thành'), findsOneWidget);
      expect(find.text('Cần làm'), findsOneWidget);
      expect(find.text('Tỷ lệ'), findsOneWidget);

      final habitNameFinder = find.text('Đọc sách mỗi ngày');
      await tester.scrollUntilVisible(
        habitNameFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(habitNameFinder, findsOneWidget);
    });
  });
}
