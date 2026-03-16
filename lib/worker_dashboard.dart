import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'job_repository.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    FindJobsPage(),
    ApprovedJobsPage(),
    WorkerDetailsPage(),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Find Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Approved Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Details',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        onTap: _onItemTapped,
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
  String? _submittingJobId;

  String _readableError(Object error) {
    return error.toString().replaceFirst('Bad state: ', '').trim();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _buildLandownerRating(String landownerId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: JobRepository.getLandownerMetrics(landownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Loading rating...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
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
                size: 16,
                color: index < avgRating.round() ? Colors.amber : Colors.grey[300],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${avgRating.toStringAsFixed(1)} ($totalRatings)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyForJob(JobRecord job) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to apply.')),
      );
      return;
    }

    final profile = await AuthService.getCurrentUserProfile();
    final workerName = (profile?['name'] as String?)?.trim();
    final workerPhone = (profile?['phone'] as String?)?.trim() ?? '';

    setState(() {
      _submittingJobId = job.id;
    });

    try {
      await JobRepository.submitApplication(
        job: job,
        workerId: workerId,
        workerName: workerName == null || workerName.isEmpty
            ? 'Worker'
            : workerName,
        workerPhone: workerPhone,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableError(error))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submittingJobId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.brown, Colors.orangeAccent],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Jobs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover cinnamon farming opportunities',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
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
                child: StreamBuilder<List<JobRecord>>(
                  stream: JobRepository.streamOpenJobs(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to load jobs right now.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    final jobs = snapshot.data ?? const <JobRecord>[];
                    if (jobs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No open jobs available yet.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final isSubmitting = _submittingJobId == job.id;
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
                                    const Icon(Icons.agriculture, color: Colors.brown),
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
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  job.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(job.location),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.payments, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('LKR ${job.paymentRate.toStringAsFixed(0)}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.group, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${job.requiredWorkers} workers'),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Posted by: ${job.landownerName} • Starts ${_formatDate(job.startDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildLandownerRating(job.landownerId),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isSubmitting ? null : () => _applyForJob(job),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Apply Now'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApprovedJobsPage extends StatefulWidget {
  const ApprovedJobsPage({super.key});

  @override
  State<ApprovedJobsPage> createState() => _ApprovedJobsPageState();
}

class _ApprovedJobsPageState extends State<ApprovedJobsPage> {
  String? _actionApplicationId;

  @override
  void initState() {
    super.initState();
    final workerId = AuthService.currentUserId;
    if (workerId != null) {
      JobRepository.expirePendingApprovalsForWorker(workerId);
    }
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst('Bad state: ', '').trim();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'expired':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _decisionWindowLabel(DateTime? deadline) {
    if (deadline == null) {
      return 'No decision deadline';
    }
    return 'Decision deadline: ${_formatDate(deadline)}';
  }

  Future<void> _acceptOffer({
    required String workerId,
    required String applicationId,
  }) async {
    setState(() {
      _actionApplicationId = applicationId;
    });

    try {
      await JobRepository.acceptApplicationDecision(
        workerId: workerId,
        applicationId: applicationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted. Other approved offers were declined.'),
        ),
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

  Future<void> _declineOffer({
    required String workerId,
    required String applicationId,
  }) async {
    setState(() {
      _actionApplicationId = applicationId;
    });

    try {
      await JobRepository.declineApplicationDecision(
        workerId: workerId,
        applicationId: applicationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offer declined.')));
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

  Future<void> _showProgressDialog({
    required String workerId,
    required WorkerApplicationRecord job,
  }) async {
    final quillController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Daily Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quillController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quill count',
                  hintText: 'e.g. 120',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any daily update',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quillCount = int.tryParse(quillController.text.trim());
                if (quillCount == null || quillCount <= 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid quill count greater than zero.'),
                    ),
                  );
                  return;
                }

                try {
                  await JobRepository.submitDailyProgress(
                    workerId: workerId,
                    applicationId: job.id,
                    quillCount: quillCount,
                    notes: notesController.text.trim(),
                  );

                  if (!mounted) {
                    return;
                  }

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Daily progress recorded.')),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(_readableError(error))),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markCompleted({
    required String workerId,
    required String applicationId,
  }) async {
    setState(() {
      _actionApplicationId = applicationId;
    });

    try {
      await JobRepository.markApplicationCompleted(
        workerId: workerId,
        applicationId: applicationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job marked as completed.')),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        return;
      }

      await _showRatingDialog(
        workerId: workerId,
        applicationId: applicationId,
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

  Future<void> _showRatingDialog({
    required String workerId,
    required String applicationId,
  }) async {
    final appRef = FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId);
    final appSnapshot = await appRef.get();
    final appData = appSnapshot.data() ?? <String, dynamic>{};

    final landownerId = appData['landownerId'] as String? ?? '';
    final landownerName = appData['landownerName'] as String? ?? 'Landowner';
    final workerProfile = await AuthService.getCurrentUserProfile();
    final workerName = (workerProfile?['name'] as String?) ?? 'Worker';

    if (!mounted) {
      return;
    }

    final ratingController = TextEditingController();
    double selectedRating = 5.0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate This Job'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How would you rate working with $landownerName?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starRating = index + 1.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedRating = starRating;
                            });
                          },
                          child: Icon(
                            Icons.star,
                            size: 36,
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
                    controller: ratingController,
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await JobRepository.submitRating(
                        fromUserId: workerId,
                        fromUserName: workerName,
                        toUserId: landownerId,
                        toUserName: landownerName,
                        jobId: applicationId,
                        rating: selectedRating,
                        feedback: ratingController.text.trim(),
                      );

                      if (!mounted) {
                        return;
                      }

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rating submitted. Thank you!')),
                      );
                    } catch (error) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_readableError(error))),
                      );
                    }
                  },
                  child: const Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProgressHistory(String applicationId) {
    return StreamBuilder<List<TaskProgressRecord>>(
      stream: JobRepository.streamProgressForApplication(applicationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Loading progress history...'),
          );
        }

        final records = snapshot.data ?? const <TaskProgressRecord>[];
        if (records.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No progress entries yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final recent = records.take(3).toList(growable: false);
        return Column(
          children: recent
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 10, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatDate(record.progressDate)} - ${record.quillCount} quills${record.notes.isEmpty ? '' : ' (${record.notes})'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workerId = AuthService.currentUserId;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.greenAccent, Colors.lightGreenAccent],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Approved Jobs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your confirmed cinnamon farming assignments',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
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
                child: workerId == null
                    ? const Center(
                        child: Text(
                          'Please sign in again to load your jobs.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : StreamBuilder<List<WorkerApplicationRecord>>(
                        stream: JobRepository.streamApplicationsForWorker(workerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'Unable to load approved jobs right now.',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            );
                          }

                          final approvedJobs =
                              snapshot.data ?? const <WorkerApplicationRecord>[];
                          if (approvedJobs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No approved jobs yet',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: approvedJobs.length,
                            itemBuilder: (context, index) {
                              final job = approvedJobs[index];
                              final isBusy = _actionApplicationId == job.id;
                              final statusColor = _statusColor(job.status);
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
                                          const Icon(Icons.check_circle, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              job.jobTitle,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(job.location)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.payments, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text('LKR ${job.paymentRate.toStringAsFixed(0)}'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start Date: ${_formatDate(job.startDate)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Landowner: ${job.landownerName}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (job.status == 'approved') ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _decisionWindowLabel(job.decisionDeadline),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          job.status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (job.status == 'approved') ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: isBusy
                                                    ? null
                                                    : () => _declineOffer(
                                                          workerId: workerId,
                                                          applicationId: job.id,
                                                        ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Decline'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isBusy
                                                    ? null
                                                    : () => _acceptOffer(
                                                          workerId: workerId,
                                                          applicationId: job.id,
                                                        ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: isBusy
                                                    ? const SizedBox(
                                                        height: 18,
                                                        width: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Colors.white,
                                                            ),
                                                      )
                                                    : const Text('Accept'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (job.status == 'accepted') ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showProgressDialog(
                                              workerId: workerId,
                                              job: job,
                                            ),
                                            icon: const Icon(Icons.edit_note),
                                            label: const Text('Record Daily Progress'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: isBusy
                                                ? null
                                                : () => _markCompleted(
                                                      workerId: workerId,
                                                      applicationId: job.id,
                                                    ),
                                            icon: const Icon(Icons.check_circle_outline),
                                            label: isBusy
                                                ? const Text('Updating...')
                                                : const Text('Mark Job Completed'),
                                          ),
                                        ),
                                      ],
                                      if (job.status == 'accepted' || job.status == 'completed') ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Recent Daily Progress',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        _buildProgressHistory(job.id),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkerDetailsPage extends StatefulWidget {
  const WorkerDetailsPage({super.key});

  @override
  State<WorkerDetailsPage> createState() => _WorkerDetailsPageState();
}

class _WorkerDetailsPageState extends State<WorkerDetailsPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await _loadProfile();
    setState(() {
      _profile = profile;
      if (_profile != null) {
        _nameController.text = _profile!['name'] ?? '';
        _phoneController.text = _profile!['phone'] ?? '';
        _experienceController.text = _profile!['experience'] ?? '';
        _skillsController.text = _profile!['skills'] ?? '';
      }
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    return await AuthService.getCurrentUserProfile();
  }

  Future<void> _updateProfile() async {
    final updates = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'experience': _experienceController.text.trim(),
      'skills': _skillsController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await AuthService.updateCurrentUserProfile(updates);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blueAccent, Colors.lightBlueAccent],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Details',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your profile information',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _experienceController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Experience',
                                prefixIcon: const Icon(Icons.work_history),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _skillsController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Skills',
                                prefixIcon: const Icon(Icons.build),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Update Profile',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}