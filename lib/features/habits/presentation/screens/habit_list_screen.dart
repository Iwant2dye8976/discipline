import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/features/habits/presentation/providers/habit_provider.dart';
import 'package:discipline/features/habits/presentation/screens/habit_form_screen.dart';
import 'package:discipline/features/habits/presentation/widgets/habit_card.dart';
import 'package:discipline/features/habits/presentation/widgets/progress_header.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  bool _showAllHabits = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HabitProvider>();
      provider.loadHabitsForDate(provider.selectedDate);
    });
  }

  void _onPreviousDay() {
    final provider = context.read<HabitProvider>();
    final newDate = provider.selectedDate.subtract(const Duration(days: 1));
    provider.setSelectedDate(newDate);
  }

  void _onNextDay() {
    final provider = context.read<HabitProvider>();
    final newDate = provider.selectedDate.add(const Duration(days: 1));
    provider.setSelectedDate(newDate);
  }

  void _onToday() {
    final provider = context.read<HabitProvider>();
    provider.setSelectedDate(DateTime.now());
  }

  Future<void> _confirmArchiveHabit(BuildContext context, Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận lưu trữ'),
        content: Text(
          'Bạn có chắc chắn muốn lưu trữ thói quen "${habit.name}" không?\n\n'
          'Thói quen sẽ được ẩn đi và các nhắc nhở sẽ được hủy. Lịch sử hoàn thành trước đây vẫn được giữ để thống kê.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lưu trữ'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<HabitProvider>();
      final success = await provider.archiveHabit(habit.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã lưu trữ thói quen "${habit.name}"'
                  : 'Lưu trữ thất bại',
            ),
          ),
        );
      }
    }
  }

  void _openAddHabit() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HabitFormScreen()));
  }

  void _openEditHabit(Habit habit) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => HabitFormScreen(habit: habit)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final displayedHabits = _showAllHabits
        ? provider.allHabits
        : provider.dueHabits;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thói quen của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Hôm nay',
            onPressed: _onToday,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with date & progress
          ProgressHeader(
            selectedDate: provider.selectedDate,
            completedCount: provider.completedCount,
            totalDueCount: provider.totalDueCount,
            progress: provider.todayProgress,
            onPreviousDate: _onPreviousDay,
            onNextDate: _onNextDay,
            onTodayDate: _onToday,
          ),

          // Filter bar: "Đến hạn hôm nay" vs "Tất cả"
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Đến hạn hôm nay'),
                  selected: !_showAllHabits,
                  onSelected: (val) {
                    if (val) setState(() => _showAllHabits = false);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Tất cả (${provider.allHabits.length})'),
                  selected: _showAllHabits,
                  onSelected: (val) {
                    if (val) setState(() => _showAllHabits = true);
                  },
                ),
              ],
            ),
          ),

          // Content list
          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading && displayedHabits.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && displayedHabits.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => provider.loadHabitsForDate(
                              provider.selectedDate,
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (displayedHabits.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAllHabits
                                ? Icons.checklist
                                : Icons.event_available,
                            size: 64,
                            color: Colors.grey.withAlpha(150),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showAllHabits
                                ? 'Chưa có thói quen nào'
                                : 'Không có thói quen cần làm hôm nay',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showAllHabits
                                ? 'Nhấn nút + bên dưới để bắt đầu tạo thói quen mới rèn luyện kỷ luật!'
                                : 'Thư giãn thôi, hoặc bạn có thể chuyển sang tab "Tất cả" để xem các thói quen khác.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          if (_showAllHabits) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _openAddHabit,
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo thói quen ngay'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 4),
                  itemCount: displayedHabits.length,
                  itemBuilder: (context, index) {
                    final habit = displayedHabits[index];
                    final isCompleted = provider.completedHabitIds.contains(
                      habit.id,
                    );

                    return HabitCard(
                      habit: habit,
                      isCompleted: isCompleted,
                      onToggle: () => provider.toggleCompletion(habit.id!),
                      onEdit: () => _openEditHabit(habit),
                      onArchive: () => _confirmArchiveHabit(context, habit),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddHabit,
        icon: const Icon(Icons.add),
        label: const Text('Thêm thói quen'),
      ),
    );
  }
}
