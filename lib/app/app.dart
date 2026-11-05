import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discipline/app/theme.dart';
import 'package:discipline/features/habits/presentation/screens/habit_list_screen.dart';
import 'package:discipline/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:discipline/features/statistics/presentation/screens/statistics_screen.dart';

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [HabitListScreen(), StatisticsScreen()];

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // Reload statistics whenever switching to the statistics tab
      context.read<StatisticsProvider>().loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Thói quen',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }
}
