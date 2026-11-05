import 'package:flutter/material.dart';
import 'package:discipline/core/utils/date_time_utils.dart';

class ProgressHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int completedCount;
  final int totalDueCount;
  final double progress;
  final VoidCallback? onPreviousDate;
  final VoidCallback? onNextDate;
  final VoidCallback? onTodayDate;

  const ProgressHeader({
    super.key,
    required this.selectedDate,
    required this.completedCount,
    required this.totalDueCount,
    required this.progress,
    this.onPreviousDate,
    this.onNextDate,
    this.onTodayDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday =
        DateTimeUtils.formatDate(selectedDate) ==
        DateTimeUtils.formatDate(DateTime.now());
    final weekdayName = DateTimeUtils.getWeekdayName(selectedDate.weekday);
    final dateDisplay =
        '$weekdayName, ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final percentage = (progress * 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date navigation row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Ngày trước',
                  onPressed: onPreviousDate,
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          dateDisplay,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isToday)
                          Text(
                            'Hôm nay',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Ngày sau',
                  onPressed: onNextDate,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiến độ hôm nay',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  totalDueCount == 0
                      ? 'Không có lịch'
                      : '$completedCount/$totalDueCount ($percentage%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: totalDueCount > 0 && completedCount == totalDueCount
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalDueCount == 0 ? 0.0 : progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  totalDueCount > 0 && completedCount == totalDueCount
                      ? Colors.green
                      : theme.colorScheme.primary,
                ),
              ),
            ),

            if (totalDueCount > 0 && completedCount == totalDueCount) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(60)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Tuyệt vời! Bạn đã hoàn thành tất cả thói quen!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
