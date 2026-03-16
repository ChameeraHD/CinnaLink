import 'package:flutter/material.dart';

import 'auth.dart';
import 'job_repository.dart';

class WorkerSchedulingPage extends StatefulWidget {
  const WorkerSchedulingPage({super.key});

  @override
  State<WorkerSchedulingPage> createState() => _WorkerSchedulingPageState();
}

class _WorkerSchedulingPageState extends State<WorkerSchedulingPage> {
  String? _actionApplicationId;

  @override
  void initState() {
    super.initState();
    final landownerId = AuthService.currentUserId;
    if (landownerId != null) {
      JobRepository.expirePendingApprovalsForLandowner(landownerId);
    }
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst('Bad state: ', '').trim();
  }

  Future<void> _updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    setState(() {
      _actionApplicationId = applicationId;
    });

    try {
      await JobRepository.updateApplicationStatus(
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
      ).showSnackBar(SnackBar(content: Text(_readableError(error))));
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

  Widget _buildApplicationList(JobRecord job) {
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
              'No workers have applied yet.',
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
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.12),
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
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          application.status.toUpperCase(),
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

  @override
  Widget build(BuildContext context) {
    final landownerId = AuthService.currentUserId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.brown, Colors.orangeAccent],
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
                      return const Center(
                        child: Text(
                          'Unable to load your jobs right now.',
                          style: TextStyle(color: Colors.white, fontSize: 18),
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
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
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
                                                  const Icon(
                                                    Icons.work_outline,
                                                    color: Colors.brown,
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
                                                      color: Colors.brown.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      job.status.toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.brown,
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
