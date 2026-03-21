import 'package:flutter/material.dart';

import '../backend/auth.dart';
import '../backend/job_repository.dart';
import '../backend/worker_scheduling_controller.dart';

class WorkerSchedulingPage extends StatefulWidget {
  const WorkerSchedulingPage({super.key});

  @override
  State<WorkerSchedulingPage> createState() => _WorkerSchedulingPageState();
}

class _WorkerSchedulingPageState extends State<WorkerSchedulingPage> {
  final WorkerSchedulingController _controller = const WorkerSchedulingController();
  String? _actionApplicationId;

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

  Future<void> _acceptGroupApplication({
    required String landownerId,
    required String groupApplicationId,
  }) async {
    setState(() {
      _actionApplicationId = groupApplicationId;
    });

    try {
      await _controller.acceptGroupApplication(
        landownerId: landownerId,
        groupApplicationId: groupApplicationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group accepted and schedules created.')),
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  String _decisionWindowLabel(DateTime? deadline) {
    if (deadline == null) {
      return 'No deadline';
    }
    return 'Decision deadline: ${_formatDate(deadline)}';
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

  String _jobStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
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
      case 'rejected':
        return 'Rejected';
      case 'declined_by_group':
        return 'Declined by Group';
      default:
        return status;
    }
  }

  Widget _buildFlowLegend() {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        item(Colors.orangeAccent, 'Under Review'),
        item(Colors.greenAccent, 'Approved'),
        item(Colors.lightBlueAccent, 'Accepted'),
        item(Colors.orange, 'In Progress'),
        item(Colors.purpleAccent, 'Completed'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
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
                color: index < avgRating.round() ? Colors.amber : Colors.grey[300],
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
    final tileBorder =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;

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
          children: applications.map((application) {
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
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        foregroundColor: statusColor,
                        child: Text(
                          application.workerName.isNotEmpty
                              ? application.workerName.substring(0, 1).toUpperCase()
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
                      Text('Pay: LKR ${application.paymentRate.toStringAsFixed(0)}'),
                      Text('Start: ${_formatDate(application.startDate)}'),
                    ],
                  ),
                  if (application.status == 'approved') ...[
                    const SizedBox(height: 6),
                    Text(
                      _decisionWindowLabel(application.decisionDeadline),
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildYieldSection(String jobId) {
    return StreamBuilder<int>(
      stream: JobRepository.streamTotalQuillCountForJob(jobId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Yield: loading...'),
          );
        }

        final total = snapshot.data ?? 0;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Cumulative Yield: $total quills',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentProgressSection(String jobId) {
    return StreamBuilder<List<TaskProgressRecord>>(
      stream: JobRepository.streamProgressForJob(jobId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Loading recent progress...'),
          );
        }

        final records = snapshot.data ?? const <TaskProgressRecord>[];
        if (records.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No progress submitted yet for this job.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final recent = records.take(3).toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Recent Progress Updates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...recent.map(
              (record) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_formatDate(record.progressDate)} - ${record.workerName}: ${record.quillCount} quills${record.notes.isEmpty ? '' : ' (${record.notes})'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
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
    final tileBorder =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300;

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

        final applications = snapshot.data ?? const <GroupJobApplicationRecord>[];
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
          children: applications.map((application) {
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
                            child: const Text('Reject Group'),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                                : const Text('Approve Group'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (application.status == 'approved') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _acceptGroupApplication(
                                  landownerId: landownerId,
                                  groupApplicationId: application.id,
                                ),
                        icon: const Icon(Icons.playlist_add_check_circle),
                        label: isBusy
                            ? const Text('Processing...')
                            : const Text('Accept Group & Create Schedules'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final landownerId = AuthService.currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF15110D), Color(0xFF2E2214)]
        : const [Colors.brown, Colors.orangeAccent];
    final headerTileColor = isDark
      ? const Color(0xFF241B15)
        : Colors.white.withValues(alpha: 0.9);
    final bodySurface = isDark ? const Color(0xFF18130F) : Colors.white;
    final accentColor = isDark ? const Color(0xFFD7A86E) : Colors.brown;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: shellTopColors,
          ),
        ),
        child: SafeArea(
          child: landownerId == null
              ? const Center(
                  child: Text(
                    'Please sign in again to manage applications.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : StreamBuilder<List<JobRecord>>(
                  stream: JobRepository.streamJobsForLandowner(landownerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      final errorMessage = snapshot.error?.toString() ??
                          'Unknown error';
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Unable to load your jobs right now.\n$errorMessage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    final jobs = snapshot.data ?? const <JobRecord>[];
                    final openJobs = jobs.where((job) => job.status == 'open').length;
                    final totalApplicants = jobs.fold<int>(
                      0,
                      (sum, job) => sum + job.applicantCount,
                    );

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Worker Scheduling',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Review applicants and track cumulative yield',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildFlowLegend(),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: headerTileColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatCard(
                                      'Jobs',
                                      jobs.length.toString(),
                                      Colors.blue,
                                    ),
                                    _buildStatCard(
                                      'Open',
                                      openJobs.toString(),
                                      Colors.green,
                                    ),
                                    _buildStatCard(
                                      'Applicants',
                                      totalApplicants.toString(),
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: bodySurface,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: jobs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Post a job first to start receiving applications.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.all(20),
                                    children: jobs.map((job) {
                                      return Card(
                                        elevation: 4,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.work_outline,
                                                    color: accentColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      job.title,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: accentColor.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      _jobStatusLabel(job.status),
                                                      style: TextStyle(
                                                        color: accentColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(job.description),
                                              const SizedBox(height: 12),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 8,
                                                children: [
                                                  Text('Type: ${job.jobType}'),
                                                  Text('Workers: ${job.requiredWorkers}'),
                                                  Text('Applicants: ${job.applicantCount}'),
                                                  Text('Start: ${_formatDate(job.startDate)}'),
                                                ],
                                              ),
                                              _buildYieldSection(job.id),
                                              _buildRecentProgressSection(job.id),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Applications',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              _buildApplicationList(job),
                                              const SizedBox(height: 14),
                                              const Text(
                                                'Group Applications',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              _buildGroupApplicationList(
                                                job: job,
                                                landownerId: landownerId,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(growable: false),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
