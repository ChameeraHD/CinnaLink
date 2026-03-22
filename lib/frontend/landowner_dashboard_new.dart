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
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Applications',
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

class WorkerApplicationsPage extends StatefulWidget {
  const WorkerApplicationsPage({super.key});

  @override
  State<WorkerApplicationsPage> createState() => _WorkerApplicationsPageState();
}

class _WorkerApplicationsPageState extends State<WorkerApplicationsPage> {
  final WorkerSchedulingController _controller =
      const WorkerSchedulingController();
  String? _actionApplicationId;
  final Map<String, Future<List<String>>> _groupMemberNamesFutures =
      <String, Future<List<String>>>{};
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

  Future<List<String>> _resolveGroupMemberNames(
    GroupJobApplicationRecord application,
  ) {
    if (application.memberNames.isNotEmpty) {
      return Future<List<String>>.value(application.memberNames);
    }

    return _groupMemberNamesFutures.putIfAbsent(
      application.id,
      () => JobRepository.fetchGroupMemberNames(
        groupId: application.groupId,
        fallbackMemberIds: application.memberIds,
      ),
    );
  }

  Widget _buildWorkerRating(String workerId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: JobRepository.getWorkerMetrics(workerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 0);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(height: 0);
        }

        final metrics = snapshot.data ?? {};
        final avgRating = (metrics['averageRating'] as num?)?.toDouble() ?? 0;
        final totalRatings = (metrics['totalRatings'] as num?)?.toInt() ?? 0;

        if (avgRating == 0) {
          return const SizedBox(height: 0);
        }

        return Row(
          children: [
            ...List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 14,
                color: index < avgRating.round()
                    ? Colors.amber
                    : Colors.grey[300],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${avgRating.toStringAsFixed(1)} ($totalRatings)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        );
      },
    );
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
        if (applications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No applications.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: applications
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
                                const SizedBox(height: 4),
                                _buildWorkerRating(application.workerId),
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
                      if (application.status == 'submitted') ...[
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
        if (applications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No group applications yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: applications
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
                      FutureBuilder<List<String>>(
                        future: _resolveGroupMemberNames(application),
                        builder: (context, memberSnapshot) {
                          final names = memberSnapshot.data ?? const <String>[];
                          final memberLabel = names.isEmpty
                              ? 'Members: ${application.memberIds.length}'
                              : 'Members: ${names.join(', ')}';
                          return Text(
                            memberLabel,
                            style: const TextStyle(color: Colors.grey),
                          );
                        },
                      ),
                      if (application.status == 'submitted') ...[
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
    final bodyColor = isDark ? const Color(0xFF18130F) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Applications'),
        backgroundColor: Colors.green,
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view applications.'))
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

                // Filter jobs with pending applications (submitted status)
                final jobsWithApplications = jobs
                    .where(
                      (job) =>
                          job.applicantCount > 0 || job.groupApplicantCount > 0,
                    )
                    .toList();

                if (jobsWithApplications.isEmpty) {
                  return const Center(
                    child: Text('No jobs with pending applications.'),
                  );
                }

                return Container(
                  color: bodyColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobsWithApplications.length,
                    itemBuilder: (context, index) {
                      final job = jobsWithApplications[index];
                      final isExpanded = _expandedJobs[job.id] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Applicants: ${job.applicantCount} | Groups: ${job.groupApplicantCount}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
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
                );
              },
            ),
    );
  }
}
