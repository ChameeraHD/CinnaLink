import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final jobsSnapshot = await _firestore.collection('jobs').get();

    final users = usersSnapshot.docs;
    final jobs = jobsSnapshot.docs;

    final roleCounts = <String, int>{};
    for (final user in users) {
      final role = user.data()['role'] as String? ?? 'unknown';
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    final statusCounts = <String, int>{};
    for (final job in jobs) {
      final status = job.data()['status'] as String? ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    setState(() {
      _stats = {
        'Total Users': users.length,
        'Workers': roleCounts['worker'] ?? 0,
        'Landowners': roleCounts['landowner'] ?? 0,
        'Admins': roleCounts['admin'] ?? 0,
        'Total Jobs': jobs.length,
        'Active Jobs': statusCounts['active'] ?? 0,
        'Completed Jobs': statusCounts['completed'] ?? 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Platform Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildStatCard(
              'Total Users',
              _stats['Total Users'] ?? 0,
              Icons.people,
            ),
            _buildStatCard(
              'Workers',
              _stats['Workers'] ?? 0,
              Icons.engineering,
            ),
            _buildStatCard(
              'Landowners',
              _stats['Landowners'] ?? 0,
              Icons.business,
            ),
            _buildStatCard(
              'Admins',
              _stats['Admins'] ?? 0,
              Icons.admin_panel_settings,
            ),
            const SizedBox(height: 20),
            const Text(
              'Job Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildStatCard('Total Jobs', _stats['Total Jobs'] ?? 0, Icons.work),
            _buildStatCard(
              'Active Jobs',
              _stats['Active Jobs'] ?? 0,
              Icons.play_circle,
            ),
            _buildStatCard(
              'Completed Jobs',
              _stats['Completed Jobs'] ?? 0,
              Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
