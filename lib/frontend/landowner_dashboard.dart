import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../backend/auth.dart';
import '../backend/job_repository.dart';
import '../backend/worker_scheduling_controller.dart';
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
    WorkerApplicationsPage(),
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
    final navAccent = isDark
        ? const Color(0xFFD7A86E)
        : const Color.fromARGB(255, 221, 128, 103);
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
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Applications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule_outlined),
                activeIcon: Icon(Icons.schedule),
                label: 'Fixed Jobs',
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

class WorkerApplicationsPage extends StatefulWidget {
  const WorkerApplicationsPage({super.key});

  @override
  State<WorkerApplicationsPage> createState() => _WorkerApplicationsPageState();
}

class _WorkerApplicationsPageState extends State<WorkerApplicationsPage> {
  final WorkerSchedulingController _controller =
      const WorkerSchedulingController();
  String? _actionApplicationId;
  final Map<String, bool> _expandedJobs = <String, bool>{};

  @override
  void initState() {
    super.initState();
    final landownerId = AuthService.currentUserId;
    if (landownerId != null) {
      JobRepository.expirePendingApprovalsForLandowner(landownerId);
    }
  }

  Future<void> _updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    setState(() {
      _actionApplicationId = applicationId;
    });

    try {
      await _controller.updateApplicationStatus(
        applicationId: applicationId,
        status: status,
      );

      if (!mounted) {
        return;
      }

      final statusLabel = status == 'approved' ? 'approved' : 'rejected';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $statusLabel successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_controller.readableError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _actionApplicationId = null;
        });
      }
    }
  }

  Future<void> _updateGroupApplicationStatus({
    required String groupApplicationId,
    required String status,
  }) async {
    setState(() {
      _actionApplicationId = groupApplicationId;
    });

    try {
      await _controller.updateGroupApplicationStatus(
        groupApplicationId: groupApplicationId,
        status: status,
      );

      if (!mounted) {
        return;
      }

      final statusLabel = status == 'approved' ? 'approved' : 'rejected';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group application $statusLabel successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_controller.readableError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _actionApplicationId = null;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.purple;
      case 'rejected':
      case 'expired':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _applicationStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  String _groupStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'declined_by_group':
        return 'Declined by Group';
      default:
        return status;
    }
  }

  Widget _buildApplicationList(JobRecord job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? const Color(0xFF14201D) : Colors.grey.shade50;
    final tileBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return StreamBuilder<List<WorkerApplicationRecord>>(
      stream: JobRepository.streamApplicationsForJob(job.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Unable to load applications for this job.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final applications = snapshot.data ?? const <WorkerApplicationRecord>[];
        final pendingApplications = applications
            .where((app) => app.status == 'submitted')
            .toList();

        if (pendingApplications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No pending applications.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: pendingApplications
              .map((application) {
                final isBusy = _actionApplicationId == application.id;
                final statusColor = _statusColor(application.status);
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tileBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: statusColor.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: statusColor,
                            child: Text(
                              application.workerName.isNotEmpty
                                  ? application.workerName
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : '?',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  application.workerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (application.workerPhone.isNotEmpty)
                                  Text(
                                    application.workerPhone,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _applicationStatusLabel(application.status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Pay: LKR ${application.paymentRate.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _updateApplicationStatus(
                                      applicationId: application.id,
                                      status: 'rejected',
                                    ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _updateApplicationStatus(
                                      applicationId: application.id,
                                      status: 'approved',
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                              ),
                              child: isBusy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildGroupApplicationList({
    required JobRecord job,
    required String landownerId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? const Color(0xFF14201D) : Colors.grey.shade50;
    final tileBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade300;

    return StreamBuilder<List<GroupJobApplicationRecord>>(
      stream: JobRepository.streamGroupApplicationsForJob(job.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Loading group applications...'),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Unable to load group applications right now.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final applications =
            snapshot.data ?? const <GroupJobApplicationRecord>[];
        final pendingGroupApplications = applications
            .where((app) => app.status == 'submitted')
            .toList();

        if (pendingGroupApplications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No pending group applications.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: pendingGroupApplications
              .map((application) {
                final isBusy = _actionApplicationId == application.id;
                final statusColor = _statusColor(application.status);

                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tileBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              application.groupName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _groupStatusLabel(application.status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Coordinator: ${application.coordinatorName}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Members: ${application.memberIds.length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _updateGroupApplicationStatus(
                                      groupApplicationId: application.id,
                                      status: 'rejected',
                                    ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _updateGroupApplicationStatus(
                                      groupApplicationId: application.id,
                                      status: 'approved',
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: isBusy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF1A130F), Color(0xFF352417)]
        : const [Color(0xFF8D5A2B), Color(0xFFC58A45)];

    return Scaffold(
      backgroundColor: const Color(0xFF8D5A2B),
      appBar: AppBar(
        title: const Text(
          'Review Applications',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            // Change this to your preferred color
          ),
        ),
        backgroundColor: const Color(0xFF8D5A2B),
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please sign in to view applications.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<List<JobRecord>>(
              stream: JobRepository.streamJobsForLandowner(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final jobs = snapshot.data ?? const <JobRecord>[];

                if (jobs.isEmpty) {
                  return const Center(child: Text('No jobs posted yet.'));
                }

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final isExpanded = _expandedJobs[job.id] ?? false;

                        return Card(
                          elevation: 0,
                          color: Colors.grey[100],
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _expandedJobs[job.id] =
                                          !(_expandedJobs[job.id] ?? false);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Job ID: ${job.id}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: const Color(0xFF8D5A2B),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Individual Applications',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildApplicationList(job),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Group Applications',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildGroupApplicationList(
                                    job: job,
                                    landownerId: user.uid,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
