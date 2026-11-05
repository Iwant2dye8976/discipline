import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discipline/core/utils/date_time_utils.dart';
import 'package:discipline/features/statistics/domain/statistics_calculator.dart';
import 'package:discipline/features/statistics/presentation/providers/statistics_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  String _formatRange(StatisticsPeriod period, DateTime start, DateTime end) {
    switch (period) {
      case StatisticsPeriod.day:
        final weekday = DateTimeUtils.getWeekdayName(start.weekday);
        return '$weekday, ${start.day}/${start.month}/${start.year}';
      case StatisticsPeriod.week:
        return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
      case StatisticsPeriod.month:
        return 'Tháng ${start.month}/${start.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StatisticsProvider>();
    final summary = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống kê tiến độ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SegmentedButton<StatisticsPeriod>(
              segments: const [
                ButtonSegment(value: StatisticsPeriod.day, label: Text('Ngày')),
                ButtonSegment(
                  value: StatisticsPeriod.week,
                  label: Text('Tuần'),
                ),
                ButtonSegment(
                  value: StatisticsPeriod.month,
                  label: Text('Tháng'),
                ),
              ],
              selected: {provider.selectedPeriod},
              onSelectionChanged: (val) {
                provider.setPeriod(val.first);
              },
            ),
          ),

          // Date navigator row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Kỳ trước',
                  onPressed: () => provider.previousPeriod(),
                ),
                Text(
                  _formatRange(
                    provider.selectedPeriod,
                    provider.startDate,
                    provider.endDate,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Kỳ sau',
                  onPressed: () => provider.nextPeriod(),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading && summary == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (summary == null || !summary.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_outlined,
                            size: 64,
                            color: Colors.grey.withAlpha(150),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có dữ liệu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Không có thói quen nào cần thực hiện trong khoảng thời gian này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Overview Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Hoàn thành',
                            value: '${summary.completedOccurrences}',
                            subtitle: 'lượt',
                            color: Colors.green,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Cần làm',
                            value: '${summary.scheduledOccurrences}',
                            subtitle: 'lượt',
                            color: theme.colorScheme.primary,
                            icon: Icons.flag_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Tỷ lệ',
                            value:
                                '${summary.completionRate.toStringAsFixed(1)}%',
                            subtitle: 'đạt mục tiêu',
                            color: Colors.orange,
                            icon: Icons.trending_up,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Chart
                    Text(
                      'Biểu đồ số lần hoàn thành',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _buildDailyChart(context, summary),
                    ),

                    const SizedBox(height: 28),

                    // Habit Breakdown
                    Text(
                      'Chi tiết từng thói quen',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...summary.habitBreakdown.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.habitName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    item.scheduledOccurrences == 0
                                        ? 'Chưa có lịch'
                                        : '${item.completedOccurrences}/${item.scheduledOccurrences} (${item.completionRate.toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          item.scheduledOccurrences > 0 &&
                                              item.completedOccurrences ==
                                                  item.scheduledOccurrences
                                          ? Colors.green
                                          : theme.colorScheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item.scheduledOccurrences == 0
                                      ? 0.0
                                      : item.completionRate / 100.0,
                                  minHeight: 6,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    item.scheduledOccurrences > 0 &&
                                            item.completedOccurrences ==
                                                item.scheduledOccurrences
                                        ? Colors.green
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart(BuildContext context, StatisticsSummary summary) {
    final theme = Theme.of(context);
    final entries = summary.dailyCompletedCounts.entries.toList();

    if (entries.isEmpty) {
      return const Center(child: Text('Không có dữ liệu biểu đồ'));
    }

    // Limit to max 14 bars for readable display
    final displayEntries = entries.length > 14
        ? entries.sublist(entries.length - 14)
        : entries;

    final barGroups = <BarChartGroupData>[];
    double maxY = 1;

    for (int i = 0; i < displayEntries.length; i++) {
      final val = displayEntries[i].value.toDouble();
      if (val > maxY) maxY = val;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: theme.colorScheme.primary,
              width: displayEntries.length > 7 ? 12 : 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + 1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dateStr = displayEntries[group.x].key;
              return BarTooltipItem(
                '$dateStr\n${rod.toY.round()} hoàn thành',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                if (value == value.roundToDouble() && value >= 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < displayEntries.length) {
                  final date = DateTimeUtils.parseDate(displayEntries[idx].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
