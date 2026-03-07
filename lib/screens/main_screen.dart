import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'entries_screen.dart';
import 'reports_screen.dart';
import 'batch_add_entries_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    BatchAddEntriesScreen(),
    EntriesScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: Colors.blue[50],
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
                color: Colors.blueAccent,
              ),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(
                Icons.add_box_rounded,
                color: Colors.blueAccent,
              ),
              label: 'Add Entry',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(
                Icons.history_rounded,
                color: Colors.blueAccent,
              ),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(
                Icons.pie_chart_rounded,
                color: Colors.blueAccent,
              ),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
