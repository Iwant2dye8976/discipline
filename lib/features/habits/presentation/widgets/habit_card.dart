import 'package:flutter/material.dart';
import 'package:discipline/core/constants/app_constants.dart';
import 'package:discipline/core/utils/date_time_utils.dart';
import 'package:discipline/data/models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String scheduleText;
    if (habit.frequencyType == AppConstants.frequencyDaily) {
      scheduleText = 'Hằng ngày';
    } else {
      final days = habit.customDays
          .map((d) => DateTimeUtils.getWeekdayName(d))
          .join(', ');
      scheduleText = days.isEmpty ? 'Tùy chỉnh' : days;
    }

    String? reminderText;
    if (habit.reminderEnabled &&
        habit.reminderHour != null &&
        habit.reminderMinute != null) {
      final hourStr = habit.reminderHour!.toString().padLeft(2, '0');
      final minuteStr = habit.reminderMinute!.toString().padLeft(2, '0');
      reminderText = '$hourStr:$minuteStr';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isCompleted ? 0.5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withAlpha(80)
              : theme.colorScheme.outlineVariant.withAlpha(50),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      color: isCompleted
          ? Colors.green.withAlpha(12)
          : theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Completion Check Button
              Semantics(
                label: isCompleted
                    ? 'Đánh dấu chưa hoàn thành thói quen ${habit.name}'
                    : 'Đánh dấu hoàn thành thói quen ${habit.name}',
                button: true,
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 26)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Habit Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isCompleted
                            ? theme.textTheme.bodyMedium?.color?.withAlpha(150)
                            : null,
                      ),
                    ),
                    if (habit.description != null &&
                        habit.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        habit.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withAlpha(
                            180,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),

                    // Tags: Schedule & Reminder
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withAlpha(
                              100,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scheduleText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        if (reminderText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withAlpha(100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 12,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  reminderText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // More action (Archive/Delete)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: 'Tùy chọn',
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'archive') {
                    onArchive();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Lưu trữ', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
