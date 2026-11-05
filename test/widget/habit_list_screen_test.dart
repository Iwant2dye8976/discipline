import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/features/habits/presentation/providers/habit_provider.dart';
import 'package:discipline/features/habits/presentation/screens/habit_list_screen.dart';

import '../unit/habit_provider_test.dart';

void main() {
  late FakeHabitRepository repository;
  late FakeNotificationService notificationService;
  late HabitProvider provider;

  setUp(() {
    repository = FakeHabitRepository();
    notificationService = FakeNotificationService();
    provider = HabitProvider(
      repository: repository,
      notificationService: notificationService,
    );
  });

  Widget buildTestableWidget() {
    return ChangeNotifierProvider<HabitProvider>.value(
      value: provider,
      child: const MaterialApp(home: HabitListScreen()),
    );
  }

  group('HabitListScreen Widget Tests', () {
    testWidgets('displays empty state when there are no habits', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Không có thói quen cần làm hôm nay'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays habit cards and toggles completion when checked', (
      tester,
    ) async {
      await repository.insertHabit(
        Habit(
          name: 'Đọc sách 20 trang',
          frequencyType: 'daily',
          reminderEnabled: false,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Đọc sách 20 trang'), findsOneWidget);
      expect(find.text('0/1 (0%)'), findsOneWidget);

      // Tap completion button (InkWell with check semantics)
      final checkButton = find.bySemanticsLabel(
        'Đánh dấu hoàn thành thói quen Đọc sách 20 trang',
      );
      expect(checkButton, findsOneWidget);

      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      expect(find.text('1/1 (100%)'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
