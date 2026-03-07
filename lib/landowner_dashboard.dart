import 'package:flutter/material.dart';
import 'job_posting_page.dart';
import 'worker_scheduling_page.dart';
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
    AccountSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
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
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: 'Account',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}