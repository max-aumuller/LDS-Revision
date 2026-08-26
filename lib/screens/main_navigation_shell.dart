import 'package:flutter/material.dart';
import 'data_browser_screen.dart';
import 'home_screen.dart';
import 'quiz_mode_select_screen.dart';
import 'past_papers_screen.dart';
import 'progress_screen.dart';
import '../theme.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const DataBrowserScreen(),
      const QuizModeSelectScreen(),
      const PastPapersScreen(),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Data'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Past Papers'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progress'),
        ],
      ),
    );
  }
}