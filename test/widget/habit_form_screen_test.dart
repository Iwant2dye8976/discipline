import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:discipline/core/services/notification_service.dart';
import 'package:discipline/features/habits/presentation/providers/habit_provider.dart';
import 'package:discipline/features/habits/presentation/screens/habit_form_screen.dart';

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

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<HabitProvider>.value(value: provider),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('HabitFormScreen Widget Tests', () {
    testWidgets('shows validation error when habit name is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(const HabitFormScreen()));

      final saveButton = find.widgetWithText(FilledButton, 'Lưu thói quen');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Tên thói quen không được để trống'), findsOneWidget);
    });

    testWidgets(
      'shows validation error when custom frequency has no days selected',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(const HabitFormScreen()));

        // Enter valid name
        await tester.enterText(
          find.byKey(const Key('habit_name_field')),
          'Tập thể dục',
        );

        // Select Custom frequency
        await tester.tap(find.text('Tùy chỉnh ngày'));
        await tester.pumpAndSettle();

        // Submit without selecting any days
        final saveButton = find.widgetWithText(FilledButton, 'Lưu thói quen');
        await tester.scrollUntilVisible(
          saveButton,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Vui lòng chọn ít nhất một ngày trong tuần'),
          findsOneWidget,
        );
      },
    );

    testWidgets('toggling reminder switch requests notifications permission', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(const HabitFormScreen()));

      final reminderSwitch = find.byType(SwitchListTile);
      await tester.scrollUntilVisible(
        reminderSwitch,
        100,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();

      expect(notificationService.requestedPermissionsCount, equals(1));
    });
  });
}
