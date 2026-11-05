# Habit Tracker MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a robust, offline-first personal Habit Tracker Flutter application with SQLite persistence, frequency scheduling, completion tracking, local reminders, and progress statistics in Vietnamese.

**Architecture:** Feature-first layered architecture (`presentation`, `domain`, `data`, `core`). State is managed cleanly using `provider`. Data persistence uses `sqflite` with parameterized queries, foreign keys, and transactions. Business logic for schedules and statistics is isolated from UI and verified with unit tests.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, `provider`, `sqflite`, `path`, `intl`, `flutter_local_notifications`, `fl_chart`, `sqflite_common_ffi` (dev/test).

**Spec:** [docs/SPEC.md](file:///C:/Dart/discipline/docs/SPEC.md) & [AGENTS.md](file:///C:/Dart/discipline/AGENTS.md)

## Global Constraints

- Vietnamese UI copy and date/time formatting.
- `completion_date` stored in local date format `YYYY-MM-DD`.
- Week starts on Monday (Thứ 2 = weekday 1, Chủ Nhật = weekday 7).
- Soft delete via `is_archived = 1` preserves completion history for statistics.
- No direct SQL or heavy business logic in Widget `build()`.
- Optimistic UI updates must rollback on persistence error.
- Unique constraint on `(habit_id, completion_date)` prevents duplicate completions.
- Foreign key pragma enabled: `PRAGMA foreign_keys = ON`.
- No division by zero in statistics; if scheduled occurrences = 0, display "Chưa có dữ liệu" or 0%.

## Review Focus

1. Habit scheduled for specific weekdays (e.g., Mon, Wed, Fri) viewed on an off-day (e.g., Tue): Must not appear in today's due list or denominator of today's progress.
2. Deleting/archiving a habit with active local notifications: Must safely cancel all scheduled notification IDs.
3. Rapid tapping on completion checkbox: Must handle concurrency without duplicate `habit_completions` rows or DB crash.
4. Statistics calculation across week/month boundary: Must only count occurrences on or after habit's `created_at` and on scheduled weekdays.
5. User revokes or denies notification permissions: Form saving must succeed and app remains fully usable without crashing.

---

### Task 1: Setup Dependencies and Core Utilities

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/utils/date_time_utils.dart`
- Create: `test/unit/date_time_utils_test.dart`

**Interfaces:**
- Produces:
  - `DateTimeUtils.formatDate(DateTime date) -> String` (returns `YYYY-MM-DD`)
  - `DateTimeUtils.parseDate(String dateStr) -> DateTime`
  - `DateTimeUtils.getStartOfWeek(DateTime date) -> DateTime` (Monday 00:00:00)
  - `DateTimeUtils.getEndOfWeek(DateTime date) -> DateTime` (Sunday 23:59:59)
  - `DateTimeUtils.getStartOfMonth(DateTime date) -> DateTime` (1st day 00:00:00)
  - `DateTimeUtils.getEndOfMonth(DateTime date) -> DateTime` (Last day 23:59:59)
  - `DateTimeUtils.getWeekdayName(int weekday) -> String` (Thứ 2 .. Chủ Nhật)

- [ ] **Step 1: Update dependencies in `pubspec.yaml`**

Add `provider`, `sqflite`, `path`, `intl`, `flutter_local_notifications`, `fl_chart`, and `sqflite_common_ffi` (in dev_dependencies). Run `flutter pub get`.

- [ ] **Step 2: Write failing unit test for `DateTimeUtils`**

Test formatting `DateTime(2026, 11, 6)` to `"2026-11-06"`, parsing `"2026-11-06"`, calculating start/end of week for a Friday (start Monday, end Sunday), and weekday naming.

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/unit/date_time_utils_test.dart`
Expected: Compilation failure (missing `DateTimeUtils`).

- [ ] **Step 4: Implement `DateTimeUtils` and `AppConstants`**

Create `lib/core/constants/app_constants.dart` with table names and standard keys. Implement `lib/core/utils/date_time_utils.dart`.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/date_time_utils_test.dart`
Expected: All tests pass.

---

### Task 2: Data Models and SQLite Database Layer

**Files:**
- Create: `lib/data/models/habit_model.dart`
- Create: `lib/data/models/habit_day_model.dart`
- Create: `lib/data/models/habit_completion_model.dart`
- Create: `lib/data/database/app_database.dart`
- Create: `lib/data/repositories/habit_repository.dart`
- Create: `lib/data/repositories/sqlite_habit_repository.dart`
- Create: `test/unit/sqlite_habit_repository_test.dart`

**Interfaces:**
- Produces:
  - `class Habit`: `id`, `name`, `description`, `frequencyType` ('daily'|'custom'), `reminderEnabled`, `reminderHour`, `reminderMinute`, `isArchived`, `createdAt`, `updatedAt`, `customDays: List<int>`
  - `class HabitCompletion`: `id`, `habitId`, `completionDate`, `completedAt`
  - `abstract class HabitRepository`:
    - `Future<List<Habit>> getActiveHabits()`
    - `Future<List<Habit>> getHabitsDueOn(DateTime date)`
    - `Future<Habit> insertHabit(Habit habit)`
    - `Future<void> updateHabit(Habit habit)`
    - `Future<void> archiveHabit(int habitId)`
    - `Future<void> deleteHabit(int habitId)`
    - `Future<bool> toggleCompletion(int habitId, String completionDate)`
    - `Future<List<HabitCompletion>> getCompletionsForDate(String completionDate)`
    - `Future<List<HabitCompletion>> getCompletionsInRange(String startDate, String endDate)`

- [ ] **Step 1: Write failing repository unit test using `sqflite_common_ffi`**

Test creating a habit with custom weekdays (e.g. [1, 3, 5]), retrieving due habits on Monday vs Tuesday, toggling completion, archiving, and unique constraint enforcement on `(habit_id, completion_date)`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/sqlite_habit_repository_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Implement Models, `AppDatabase`, and `SqliteHabitRepository`**

- `AppDatabase`: initializes database with foreign keys enabled (`PRAGMA foreign_keys = ON`), creates `habits`, `habit_days`, and `habit_completions` tables with unique indexes.
- `SqliteHabitRepository`: executes operations in transactions when touching `habits` and `habit_days`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/sqlite_habit_repository_test.dart`
Expected: All tests pass.

---

### Task 3: Local Notification Reminder Service

**Files:**
- Create: `lib/core/services/notification_service.dart`
- Create: `test/unit/notification_service_test.dart`

**Interfaces:**
- Produces:
  - `class NotificationService`:
    - `Future<void> init()`
    - `Future<bool> requestPermissions()`
    - `int generateNotificationId(int habitId, int weekday)`
    - `Future<void> scheduleHabitReminder(Habit habit)`
    - `Future<void> cancelHabitReminders(Habit habit)`

- [ ] **Step 1: Write unit test for notification ID generation and scheduling rules**

Verify `generateNotificationId` produces distinct, deterministic IDs for each `(habitId, weekday)` pair and that cancelling calls cancel for all scheduled weekdays.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/notification_service_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Implement `NotificationService`**

Implement `flutter_local_notifications` setup with Android & iOS initialization, channels, stable notification ID generation, and permission request handling with graceful fallback.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/notification_service_test.dart`
Expected: All tests pass.

---

### Task 4: State Management (Habit Provider)

**Files:**
- Create: `lib/features/habits/presentation/providers/habit_provider.dart`
- Create: `test/unit/habit_provider_test.dart`

**Interfaces:**
- Produces:
  - `class HabitProvider extends ChangeNotifier`:
    - `DateTime selectedDate`
    - `bool isLoading`
    - `String? errorMessage`
    - `List<Habit> dueHabits`
    - `List<Habit> allHabits`
    - `Set<int> completedHabitIds`
    - `Future<void> loadHabitsForDate(DateTime date)`
    - `Future<void> addHabit(Habit habit)`
    - `Future<void> updateHabit(Habit habit)`
    - `Future<void> archiveHabit(int habitId)`
    - `Future<void> toggleCompletion(int habitId)`
    - `int get completedCount`
    - `int get totalDueCount`
    - `double get todayProgress`

- [ ] **Step 1: Write unit test for `HabitProvider`**

Test optimistic completion toggle (state changes immediately, reverts if repository throws), loading habits for date, and progress calculation.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/habit_provider_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Implement `HabitProvider`**

Wire `HabitRepository` and `NotificationService` into `HabitProvider`, handle loading/error states, and update listeners.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/habit_provider_test.dart`
Expected: All tests pass.

---

### Task 5: Habit UI (Habit List & Form Screens)

**Files:**
- Create: `lib/features/habits/presentation/screens/habit_list_screen.dart`
- Create: `lib/features/habits/presentation/screens/habit_form_screen.dart`
- Create: `lib/features/habits/presentation/widgets/habit_card.dart`
- Create: `lib/features/habits/presentation/widgets/progress_header.dart`
- Create: `test/widget/habit_list_screen_test.dart`
- Create: `test/widget/habit_form_screen_test.dart`

**Interfaces:**
- Produces:
  - `HabitListScreen`: Displays today's due habits, date navigation, progress bar, FAB to add, archive action.
  - `HabitFormScreen`: Form for creating or editing habit with validation (name non-empty 1-60 chars, weekday selection for custom, reminder time picker).

- [ ] **Step 1: Write widget test for `HabitFormScreen` validation**

Verify submitting empty name shows error "Tên thói quen không được để trống", custom frequency without weekdays shows error "Vui lòng chọn ít nhất một ngày trong tuần".

- [ ] **Step 2: Run widget test to verify it fails**

Run: `flutter test test/widget/habit_form_screen_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Implement `HabitFormScreen`, `HabitListScreen`, `HabitCard`, and `ProgressHeader`**

Implement complete UI components with responsive layouts, accessible semantic labels, Vietnamese strings, and SnackBar notifications.

- [ ] **Step 4: Run widget tests**

Run: `flutter test test/widget/habit_form_screen_test.dart test/widget/habit_list_screen_test.dart`
Expected: All tests pass.

---

### Task 6: Statistics Domain Logic and Screen

**Files:**
- Create: `lib/features/statistics/domain/statistics_calculator.dart`
- Create: `lib/features/statistics/presentation/providers/statistics_provider.dart`
- Create: `lib/features/statistics/presentation/screens/statistics_screen.dart`
- Create: `test/unit/statistics_calculator_test.dart`
- Create: `test/widget/statistics_screen_test.dart`

**Interfaces:**
- Produces:
  - `class StatisticsCalculator`:
    - `StatisticsSummary calculate({required List<Habit> habits, required List<HabitCompletion> completions, required DateTime startDate, required DateTime endDate})`
  - `class StatisticsSummary`:
    - `int scheduledOccurrences`
    - `int completedOccurrences`
    - `double completionRate` (0.0 to 100.0)
    - `Map<String, int> dailyCompletedCounts`
    - `List<HabitStatItem> habitBreakdown`
  - `StatisticsScreen`: Tabs for Ngày / Tuần / Tháng, summary cards, `fl_chart` chart, and breakdown list.

- [ ] **Step 1: Write unit test for `StatisticsCalculator`**

Test calculation when scheduled = 0 (returns 0.0 rate without division by zero), habits created mid-week (does not count days prior to `created_at`), and custom weekday matching.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/statistics_calculator_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Implement `StatisticsCalculator`, `StatisticsProvider`, and `StatisticsScreen`**

Build statistics computation and visual presentation with `fl_chart` bar chart and Vietnamese labels.

- [ ] **Step 4: Run unit and widget tests**

Run: `flutter test test/unit/statistics_calculator_test.dart test/widget/statistics_screen_test.dart`
Expected: All tests pass.

---

### Task 7: App Theme, Navigation Shell, and Entry Point

**Files:**
- Create: `lib/app/theme.dart`
- Create: `lib/app/app.dart`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Implement Theme and Navigation Shell in `lib/app/`**

Create clean Material 3 theme in Vietnamese locale with primary color palette, bottom navigation bar switching between Habit List and Statistics.

- [ ] **Step 2: Update `lib/main.dart`**

Initialize Flutter bindings, notification service, database, and wrap app in `MultiProvider`.

- [ ] **Step 3: Update `test/widget_test.dart`**

Replace default Flutter counter test with an end-to-end smoke test verifying the app boots and displays the Habit Tracker home screen.

- [ ] **Step 4: Run full test suite & analyze**

Run: `flutter test` and `flutter analyze`
Expected: 0 errors, all tests pass.
