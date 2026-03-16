import 'package:flutter/material.dart';
import 'app_state.dart';
import 'auth.dart';
import 'login_page.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  int _selectedIndex = 0;

  static const pageTitles = ['Find Jobs', 'Assigned Jobs', 'Profile'];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FindJobsPage(),
      const AssignedJobsPage(),
      const WorkerDetailsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Find Jobs'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Assigned',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class FindJobsPage extends StatefulWidget {
  const FindJobsPage({super.key});

  @override
  State<FindJobsPage> createState() => _FindJobsPageState();
}

class _FindJobsPageState extends State<FindJobsPage> {
  Future<void> _apply(String jobId) async {
    final workerId = AppState.instance.currentUser?.id ?? 'worker';
    final success = await AppState.instance.applyToJob(
      jobId: jobId,
      workerId: workerId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Applied successfully' : 'Already applied'),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final jobs = AppState.instance.jobs;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final applied = job.applications.any(
          (a) => a.workerId == AppState.instance.currentUser?.id,
        );
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(job.title),
            subtitle: Text('${job.location} • ₹${job.wage}/day'),
            trailing: ElevatedButton(
              onPressed: applied || !job.isOpen ? null : () => _apply(job.id),
              child: Text(applied ? 'Applied' : 'Apply'),
            ),
          ),
        );
      },
    );
  }
}

class AssignedJobsPage extends StatelessWidget {
  const AssignedJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final assigned = AppState.instance.jobs
        .expand(
          (job) => job.schedule.map(
            (s) =>
                'Job ${job.title} assigned to ${s.workerId} on ${s.date.toLocal().toString().split(' ').first}',
          ),
        )
        .toList();
    if (assigned.isEmpty)
      return const Center(child: Text('No assigned jobs yet.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: assigned.length,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(assigned[index]),
        ),
      ),
    );
  }
}

class WorkerDetailsPage extends StatelessWidget {
  const WorkerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser;
    return Center(
      child: Text(
        user == null ? 'No user logged in' : '${user.name} (${user.role})',
      ),
    );
  }
}
