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
  final WorkerSchedulingController _controller =
      const WorkerSchedulingController();
  String? _actionApplicationId;
  final Set<String> _ratingSubmitting = <String>{};
  final Map<String, bool> _ratedWorkers =
      {}; // Track which workers have been rated
  final Map<String, Future<List<String>>> _groupMemberNamesFutures =
      <String, Future<List<String>>>{};

  @override
  void initState() {
    super.initState();
    final landownerId = AuthService.currentUserId;
    if (landownerId != null) {
      JobRepository.expirePendingApprovalsForLandowner(landownerId);
      // Migrate existing jobs with accepted applications to 'accepted' status
      JobRepository.migrateAcceptedJobsStatus();
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

  DateTime _estimatedEndDate(DateTime startDate, int estimatedDays) {
    final inclusiveDays = estimatedDays > 0 ? estimatedDays - 1 : 0;
    return startDate.add(Duration(days: inclusiveDays));
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

  Future<void> _showWorkerRatingDialog({
    required WorkerApplicationRecord application,
  }) async {
    final landownerId = AuthService.currentUserId;
    if (landownerId == null) {
      return;
    }

    final profile = await AuthService.getCurrentUserProfile();
    final landownerName =
        (profile?['name'] as String?)?.trim().isNotEmpty == true
        ? (profile?['name'] as String)
        : 'Landowner';

    if (!mounted) {
      return;
    }

    final feedbackController = TextEditingController();
    double selectedRating = 5.0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSubmitting = _ratingSubmitting.contains(application.id);
            return AlertDialog(
              title: const Text('Rate Worker'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How would you rate ${application.workerName}?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starRating = index + 1.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: isSubmitting
                              ? null
                              : () {
                                  setDialogState(() {
                                    selectedRating = starRating;
                                  });
                                },
                          child: Icon(
                            Icons.star,
                            size: 34,
                            color: starRating <= selectedRating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Feedback (optional)',
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          setState(() {
                            _ratingSubmitting.add(application.id);
                          });

                          try {
                            await JobRepository.submitRating(
                              fromUserId: landownerId,
                              fromUserName: landownerName,
                              toUserId: application.workerId,
                              toUserName: application.workerName,
                              jobId: application.jobId,
                              rating: selectedRating,
                              feedback: feedbackController.text.trim(),
                            );

                            if (!mounted) {
                              return;
                            }

                            Navigator.of(this.context).pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Rating submitted. Thank you!'),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(_controller.readableError(error)),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _ratingSubmitting.remove(application.id);
                              });
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGroupRatingDialog({
    required GroupJobApplicationRecord application,
  }) async {
    final landownerId = AuthService.currentUserId;
    if (landownerId == null) {
      return;
    }

    final profile = await AuthService.getCurrentUserProfile();
    final landownerName =
        (profile?['name'] as String?)?.trim().isNotEmpty == true
        ? (profile?['name'] as String)
        : 'Landowner';

    if (!mounted) {
      return;
    }

    final feedbackController = TextEditingController();
    double selectedRating = 5.0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSubmitting = _ratingSubmitting.contains(application.id);
            return AlertDialog(
              title: const Text('Rate Group Members'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This rating will be submitted to all members of "${application.groupName}" (${application.memberIds.length} workers).',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starRating = index + 1.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: isSubmitting
                              ? null
                              : () {
                                  setDialogState(() {
                                    selectedRating = starRating;
                                  });
                                },
                          child: Icon(
                            Icons.star,
                            size: 34,
                            color: starRating <= selectedRating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Feedback (optional)',
                      hintText: 'Share your experience with this group...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          setState(() {
                            _ratingSubmitting.add(application.id);
                          });

                          try {
                            final result =
                                await JobRepository.submitRatingToGroupMembers(
                                  landownerId: landownerId,
                                  landownerName: landownerName,
                                  groupApplicationId: application.id,
                                  rating: selectedRating,
                                  feedback: feedbackController.text.trim(),
                                );

                            if (!mounted) {
                              return;
                            }

                            Navigator.of(this.context).pop();
                            final submitted = result['submitted'] ?? 0;
                            final skipped = result['skipped'] ?? 0;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Submitted to $submitted member(s). Skipped $skipped already-rated member(s).',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(_controller.readableError(error)),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _ratingSubmitting.remove(application.id);
                              });
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Group Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _checkIfWorkerRated({
    required String landownerId,
    required String workerId,
    required String jobId,
  }) async {
    final cacheKey = '$workerId-$jobId';
    if (_ratedWorkers.containsKey(cacheKey)) {
      return _ratedWorkers[cacheKey] ?? false;
    }

    final hasRating = await JobRepository.hasRatingForJob(
      fromUserId: landownerId,
      toUserId: workerId,
      jobId: jobId,
    );

    if (mounted) {
      setState(() {
        _ratedWorkers[cacheKey] = hasRating;
      });
    }

    return hasRating;
  }

  Widget _buildFlowLegend() {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
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

  Future<void> _showRatingsBottomSheet({
    required String jobId,
    required String jobTitle,
  }) async {
    final landownerId = AuthService.currentUserId;
    if (landownerId == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder<List<WorkerApplicationRecord>>(
          stream: JobRepository.streamApplicationsForJob(jobId),
          builder: (context, snapshot) {
            final applications =
                snapshot.data ?? const <WorkerApplicationRecord>[];
            final acceptedApplications = applications
                .where(
                  (app) =>
                      app.status == 'accepted' || app.status == 'completed',
                )
                .toList();

            return DraggableScrollableSheet(
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF18130F)
                        : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Rate Workers - $jobTitle',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: acceptedApplications.length,
                          itemBuilder: (context, index) {
                            final app = acceptedApplications[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.workerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FutureBuilder<bool>(
                                          future: _checkIfWorkerRated(
                                            landownerId: landownerId,
                                            workerId: app.workerId,
                                            jobId: jobId,
                                          ),
                                          builder: (context, ratingSnapshot) {
                                            final alreadyRated =
                                                ratingSnapshot.data ?? false;
                                            final isSubmitting =
                                                _ratingSubmitting.contains(
                                                  app.id,
                                                );

                                            return ElevatedButton.icon(
                                              onPressed:
                                                  alreadyRated || isSubmitting
                                                  ? null
                                                  : () =>
                                                        _showWorkerRatingDialog(
                                                          application: app,
                                                        ),
                                              icon: const Icon(Icons.star_rate),
                                              label: Text(
                                                alreadyRated
                                                    ? 'Already Rated'
                                                    : isSubmitting
                                                    ? 'Submitting...'
                                                    : 'Rate Worker',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: alreadyRated
                                                    ? Colors.grey
                                                    : Colors.amber,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final landownerId = AuthService.currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark ? Color(0xFF8D5A2B) : Color(0xFF8D5A2B);
    final headerTileColor = isDark
        ? const Color(0xFF241B15)
        : Colors.white.withValues(alpha: 0.9);
    final bodySurface = isDark ? const Color(0xFF18130F) : Colors.white;
    final accentColor = isDark ? const Color(0xFFD7A86E) : Colors.brown;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: shellTopColors),
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
                      final errorMessage =
                          snapshot.error?.toString() ?? 'Unknown error';
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
                    final acceptedJobs = jobs
                        .where(
                          (job) =>
                              job.status == 'accepted' ||
                              job.status == 'in_progress' ||
                              job.status == 'completed',
                        )
                        .toList();
                    final activeJobsCount = acceptedJobs
                        .where((job) => job.status == 'in_progress')
                        .length;
                    final completedJobsCount = acceptedJobs
                        .where((job) => job.status == 'completed')
                        .length;

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
                                'Track accepted jobs and cumulative yield',
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatCard(
                                      'Active',
                                      activeJobsCount.toString(),
                                      Colors.orange,
                                    ),
                                    _buildStatCard(
                                      'Completed',
                                      completedJobsCount.toString(),
                                      Colors.green,
                                    ),
                                    _buildStatCard(
                                      'Accepted',
                                      acceptedJobs.length.toString(),
                                      Colors.blue,
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
                                : acceptedJobs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No accepted jobs yet. Approved applications will appear here.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.all(20),
                                    children: acceptedJobs
                                        .map((job) {
                                          return Card(
                                            elevation: 4,
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: accentColor
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                999,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          _jobStatusLabel(
                                                            job.status,
                                                          ),
                                                          style: TextStyle(
                                                            color: accentColor,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                      Text(
                                                        'Type: ${job.jobType}',
                                                      ),
                                                      Text(
                                                        'Workers: ${job.requiredWorkers}',
                                                      ),
                                                      Text(
                                                        'Applicants: ${job.applicantCount}',
                                                      ),
                                                      Text(
                                                        'Start: ${_formatDate(job.startDate)}',
                                                      ),
                                                      Text(
                                                        'Est. End: ${_formatDate(_estimatedEndDate(job.startDate, job.estimatedDays))}',
                                                      ),
                                                    ],
                                                  ),
                                                  _buildYieldSection(job.id),
                                                  _buildRecentProgressSection(
                                                    job.id,
                                                  ),
                                                  if (job.status == 'completed')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 16,
                                                          ),
                                                      child: SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton.icon(
                                                          onPressed: () =>
                                                              _showRatingsBottomSheet(
                                                                jobId: job.id,
                                                                jobTitle:
                                                                    job.title,
                                                              ),
                                                          icon: const Icon(
                                                            Icons.star_rate,
                                                          ),
                                                          label: const Text(
                                                            'Rate Workers',
                                                          ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .amber,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(growable: false),
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
