import 'package:flutter/material.dart';
import 'job_posting_page.dart';
import 'worker_scheduling_page.dart';
import 'landowner_details_page.dart';
import 'account_settings_page.dart';

class LandownerDashboard extends StatefulWidget {
  const LandownerDashboard({super.key});

  @override
  State<LandownerDashboard> createState() => _LandownerDashboardState();
}

class _LandownerDashboardState extends State<LandownerDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    JobPostingPage(),
    WorkerSchedulingPage(),
    LandownerDetailsPage(),
    AccountSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navAccent = isDark ? const Color(0xFFD7A86E) : Colors.brown;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black12,
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Post Job',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule_outlined),
                activeIcon: Icon(Icons.schedule),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'My Details',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: navAccent,
            unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.68),
            backgroundColor: colorScheme.surface,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}