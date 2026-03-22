import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../backend/auth.dart';
import '../backend/job_repository.dart';
import 'profile_reviews_section.dart';
import 'worker_account_settings_page.dart';

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
    WorkerAccountSettingsPage(),
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
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
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
                icon: Icon(Icons.work_outline),
                activeIcon: Icon(Icons.work),
                label: 'Find Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                activeIcon: Icon(Icons.check_circle),
                label: 'Approved Jobs',
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
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.68),
            backgroundColor: colorScheme.surface,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
          ),
        ),
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
    final text = error.toString();
    if (text.contains('Dart exception thrown from converted Future')) {
      return 'Group application failed due to a web runtime error. Please try again once; if it repeats, refresh the page.';
    }
    return text.replaceFirst('Bad state: ', '').trim();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _jobEndDate(JobRecord job) {
    final inclusiveDays = job.estimatedDays > 0 ? job.estimatedDays - 1 : 0;
    return job.startDate.add(Duration(days: inclusiveDays));
  }

  DateTime _applicationEndDate(WorkerApplicationRecord application) {
    final inclusiveDays = application.estimatedDays > 0
        ? application.estimatedDays - 1
        : 0;
    return application.startDate.add(Duration(days: inclusiveDays));
  }

  bool _dateRangesOverlap({
    required DateTime firstStart,
    required DateTime firstEnd,
    required DateTime secondStart,
    required DateTime secondEnd,
  }) {
    return !firstStart.isAfter(secondEnd) && !firstEnd.isBefore(secondStart);
  }

  bool _isBlockedByAcceptedWindow({
    required JobRecord candidate,
    required List<WorkerApplicationRecord> applications,
  }) {
    final candidateStart = candidate.startDate;
    final candidateEnd = _jobEndDate(candidate);

    for (final application in applications) {
      if (application.status != 'accepted' &&
          application.status != 'in_progress') {
        continue;
      }

      final activeStart = application.startDate;
      final activeEnd = _applicationEndDate(application);
      final overlaps = _dateRangesOverlap(
        firstStart: candidateStart,
        firstEnd: candidateEnd,
        secondStart: activeStart,
        secondEnd: activeEnd,
      );

      if (overlaps) {
        return true;
      }
    }

    return false;
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
                color: index < avgRating.round()
                    ? Colors.amber
                    : Colors.grey[300],
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_readableError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _submittingJobId = null;
        });
      }
    }
  }

  Future<void> _showGroupApplyDialog(JobRecord job) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to apply as a group.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<WorkerGroupRecord>>(
              stream: JobRepository.streamGroupsForWorker(workerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('Unable to load groups right now.'),
                    ),
                  );
                }

                final allGroups = snapshot.data ?? const <WorkerGroupRecord>[];
                final coordinatedGroups = allGroups
                    .where((group) => group.coordinatorId == workerId)
                    .toList(growable: false);

                if (coordinatedGroups.isEmpty) {
                  return const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'You are not coordinating any group yet.\nCreate a group in My Details first.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apply As Group',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a group to apply for "${job.title}"',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: coordinatedGroups.length,
                        itemBuilder: (context, index) {
                          final group = coordinatedGroups[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.groups),
                              title: Text(group.groupName),
                              subtitle: Text(
                                'Members: ${group.memberIds.length}',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _applyForJobAsGroup(
                                    job: job,
                                    group: group,
                                  );
                                },
                                child: const Text('Apply'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyForJobAsGroup({
    required JobRecord job,
    required WorkerGroupRecord group,
  }) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      return;
    }

    setState(() {
      _submittingJobId = job.id;
    });

    try {
      // Check for member conflicts first
      final conflictResult = await JobRepository.getGroupApplicationConflicts(
        memberIds: group.memberIds,
        memberNames: group.memberIds
            .map(
              (id) => group.members
                  .firstWhere(
                    (m) => m['workerId'] == id,
                    orElse: () => {'workerName': 'Worker'},
                  )['workerName']
                  .toString(),
            )
            .toList(),
        jobStartDate: job.startDate,
        jobEstimatedDays: job.estimatedDays,
      );

      if (!mounted) {
        return;
      }

      // If there are conflicts, show resolution dialog
      if (conflictResult.hasConflicts) {
        await _showGroupConflictResolutionDialog(
          job: job,
          group: group,
          conflictResult: conflictResult,
        );
        return;
      }

      // No conflicts, proceed with normal submission
      await JobRepository.submitGroupApplication(
        job: job,
        groupId: group.id,
        coordinatorId: workerId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${group.groupName}" applied successfully!'),
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
          _submittingJobId = null;
        });
      }
    }
  }

  Future<void> _showGroupConflictResolutionDialog({
    required JobRecord job,
    required WorkerGroupRecord group,
    required GroupConflictResult conflictResult,
  }) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      return;
    }

    var selectedMemberIds = Set<String>.from(conflictResult.availableMembers);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Member Scheduling Conflicts'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Some members have scheduling conflicts:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...conflictResult.conflictingMembers.map(
                      (conflict) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${conflict.memberName} - Conflict:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                '${conflict.conflictingJobTitle}\n'
                                '${conflict.conflictingStartDate.toString().split(' ')[0]} - '
                                '${conflict.conflictingEndDate.toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Members who can be scheduled:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...conflictResult.availableMembers.map((memberId) {
                      final memberName = group.members
                          .firstWhere(
                            (m) => m['workerId'] == memberId,
                            orElse: () => {'workerName': 'Worker'},
                          )['workerName']
                          .toString();
                      return CheckboxListTile(
                        value: selectedMemberIds.contains(memberId),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedMemberIds.add(memberId);
                            } else {
                              selectedMemberIds.remove(memberId);
                            }
                          });
                        },
                        title: Text(memberName),
                        dense: true,
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedMemberIds.isEmpty
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          _submitGroupApplicationWithSelectedMembers(
                            job: job,
                            group: group,
                            selectedMemberIds: selectedMemberIds.toList(),
                          );
                        },
                  child: const Text('Apply With Selected Members'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitGroupApplicationWithSelectedMembers({
    required JobRecord job,
    required WorkerGroupRecord group,
    required List<String> selectedMemberIds,
  }) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      return;
    }

    setState(() {
      _submittingJobId = job.id;
    });

    try {
      // Submit with selected members only
      await JobRepository.submitGroupApplication(
        job: job,
        groupId: group.id,
        coordinatorId: workerId,
        overrideMemberIds: selectedMemberIds,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${group.groupName}" applied successfully!'),
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
          _submittingJobId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF0D1B17), Color(0xFF19352A)]
        : const [Colors.brown, Colors.orangeAccent];
    final shellSurfaceColor = isDark ? const Color(0xFF101917) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: shellTopColors,
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
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: shellSurfaceColor,
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

                    final currentWorkerId = AuthService.currentUserId;
                    if (currentWorkerId == null) {
                      return const Center(
                        child: Text(
                          'Please sign in again to apply for jobs.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return StreamBuilder<Set<String>>(
                      stream: JobRepository.streamAppliedJobIdsForWorker(
                        currentWorkerId,
                      ),
                      builder: (context, appliedSnapshot) {
                        final directAppliedJobIds =
                            appliedSnapshot.data ?? const <String>{};

                        return StreamBuilder<Map<String, String>>(
                          stream:
                              JobRepository.streamGroupAppliedJobLabelsForWorker(
                                currentWorkerId,
                              ),
                          builder: (context, groupAppliedSnapshot) {
                            final groupAppliedJobLabels =
                                groupAppliedSnapshot.data ??
                                const <String, String>{};
                            final groupAppliedJobIds = groupAppliedJobLabels
                                .keys
                                .toSet();
                            final appliedJobIds = {
                              ...directAppliedJobIds,
                              ...groupAppliedJobIds,
                            };

                            return StreamBuilder<List<WorkerApplicationRecord>>(
                              stream: JobRepository.streamApplicationsForWorker(
                                currentWorkerId,
                              ),
                              builder: (context, applicationsSnapshot) {
                                final workerApplications =
                                    applicationsSnapshot.data ??
                                    const <WorkerApplicationRecord>[];
                                final visibleJobs = jobs
                                    .where(
                                      (job) => !_isBlockedByAcceptedWindow(
                                        candidate: job,
                                        applications: workerApplications,
                                      ),
                                    )
                                    .toList(growable: false);

                                if (visibleJobs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No open jobs available for your current accepted schedule window.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: visibleJobs.length,
                                  itemBuilder: (context, index) {
                                    final job = visibleJobs[index];
                                    final isSubmitting =
                                        _submittingJobId == job.id;
                                    final hasDirectApplied = directAppliedJobIds
                                        .contains(job.id);
                                    final hasGroupApplied = groupAppliedJobIds
                                        .contains(job.id);
                                    final hasApplied = appliedJobIds.contains(
                                      job.id,
                                    );
                                    final groupName =
                                        groupAppliedJobLabels[job.id] ??
                                        'Group';
                                    final appliedLabel = hasDirectApplied
                                        ? (hasGroupApplied
                                              ? 'Applied (Individual + Group: $groupName)'
                                              : 'Applied')
                                        : 'Applied via group: $groupName';
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.agriculture,
                                                  color: Colors.brown,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    job.title,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(job.location),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.payments,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'LKR ${job.paymentRate.toStringAsFixed(0)}',
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.group,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${job.requiredWorkers} workers',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Posted by: ${job.landownerName} • Starts ${_formatDate(job.startDate)} • Est. ends ${_formatDate(_jobEndDate(job))}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            _buildLandownerRating(
                                              job.landownerId,
                                            ),
                                            if (hasApplied) ...[
                                              const SizedBox(height: 10),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  appliedLabel,
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed:
                                                        isSubmitting ||
                                                            hasApplied
                                                        ? null
                                                        : () =>
                                                              _applyForJob(job),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          hasApplied
                                                          ? Colors.grey
                                                          : Colors.brown,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    child: isSubmitting
                                                        ? const SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          )
                                                        : Text(
                                                            hasApplied
                                                                ? 'Applied'
                                                                : 'Apply Now',
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed:
                                                        isSubmitting ||
                                                            hasApplied
                                                        ? null
                                                        : () =>
                                                              _showGroupApplyDialog(
                                                                job,
                                                              ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          hasApplied
                                                          ? Colors.grey
                                                          : Colors.brown,
                                                      side: BorderSide(
                                                        color: hasApplied
                                                            ? Colors.grey
                                                            : Colors.brown,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.groups,
                                                    ),
                                                    label: const Text(
                                                      'As Group',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
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
  final Map<String, bool> _ratedJobs = {}; // Track which jobs have been rated
  bool _showIndividualApplications = true;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final List<Color> _jobColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFED64A6), // Pink
    const Color(0xFF00D084), // Green
    const Color(0xFFFFA626), // Orange
    const Color(0xFF9F7AEA), // Purple
    const Color(0xFF38B6FF), // Blue
    const Color(0xFFFCA311), // Amber
    const Color(0xFFFF6B6B), // Red
  ];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    final workerId = AuthService.currentUserId;
    if (workerId != null) {
      JobRepository.expirePendingApprovalsForWorker(workerId);
    }
  }

  String _readableError(Object error) {
    final raw = error.toString();

    if (raw.contains('converted Future')) {
      try {
        final dynamic boxed = error;
        final Object? inner = boxed.error;
        if (inner != null) {
          return inner.toString().replaceFirst('Bad state: ', '').trim();
        }
      } catch (_) {
        return 'Operation failed in web runtime. Please refresh and try again.';
      }
      return 'Operation failed in web runtime. Please refresh and try again.';
    }

    return raw.replaceFirst('Bad state: ', '').trim();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _jobEndDate(WorkerApplicationRecord job) {
    final inclusiveDays = job.estimatedDays > 0 ? job.estimatedDays - 1 : 0;
    return job.startDate.add(Duration(days: inclusiveDays));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.purple;
      case 'rejected':
      case 'declined_by_group':
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

  String _groupStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Awaiting landowner review';
      case 'approved':
        return 'Approved - coordinator decision required';
      case 'accepted':
        return 'Accepted - group schedule created';
      case 'rejected':
        return 'Rejected by landowner';
      case 'expired':
        return 'Expired - ask landowner to approve again';
      case 'declined_by_group':
        return 'Declined by group coordinator';
      default:
        return status;
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
      case 'declined_by_worker':
        return 'Declined by Worker';
      default:
        return status;
    }
  }

  Color _getJobColor(String jobId, int jobIndex) {
    return _jobColors[jobIndex % _jobColors.length];
  }

  // Helper to compare dates ignoring time component
  bool _dateIsBetweenInclusive(
    DateTime day,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return !dayOnly.isBefore(startOnly) && !dayOnly.isAfter(endOnly);
  }

  bool _hasJobOnDate(DateTime day, List<WorkerApplicationRecord> jobs) {
    return jobs.any((job) {
      final endDate = _jobEndDate(job);
      return _dateIsBetweenInclusive(day, job.startDate, endDate) &&
          (job.status == 'accepted' ||
              job.status == 'in_progress' ||
              job.status == 'completed');
    });
  }

  bool _hasJobOrGroupScheduleOnDate(
    DateTime day,
    List<WorkerApplicationRecord> jobs,
    List<Map<String, dynamic>> groupSchedules,
  ) {
    // Check individual jobs
    final hasIndividualJob = _hasJobOnDate(day, jobs);
    if (hasIndividualJob) return true;

    // Check group schedules
    return groupSchedules.any((schedule) {
      final startDate =
          (schedule['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final estimatedDays = ((schedule['estimatedDays'] as num?) ?? 1).toInt();
      final inclusiveDays = estimatedDays > 0 ? estimatedDays - 1 : 0;
      final endDate = startDate.add(Duration(days: inclusiveDays));
      final status = (schedule['status'] as String?) ?? '';
      return _dateIsBetweenInclusive(day, startDate, endDate) &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed');
    });
  }

  List<WorkerApplicationRecord> _getJobsForDate(
    DateTime day,
    List<WorkerApplicationRecord> jobs,
  ) {
    return jobs.where((job) {
      final endDate = _jobEndDate(job);
      return _dateIsBetweenInclusive(day, job.startDate, endDate) &&
          (job.status == 'accepted' ||
              job.status == 'in_progress' ||
              job.status == 'completed');
    }).toList();
  }

  List<Map<String, dynamic>> _getGroupSchedulesForDate(
    DateTime day,
    List<Map<String, dynamic>> groupSchedules,
  ) {
    return groupSchedules.where((schedule) {
      final startDate =
          (schedule['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final estimatedDays = ((schedule['estimatedDays'] as num?) ?? 1).toInt();
      final inclusiveDays = estimatedDays > 0 ? estimatedDays - 1 : 0;
      final endDate = startDate.add(Duration(days: inclusiveDays));
      final status = (schedule['status'] as String?) ?? '';
      return _dateIsBetweenInclusive(day, startDate, endDate) &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed');
    }).toList();
  }

  Widget _buildJobCalendar(
    List<WorkerApplicationRecord> jobs,
    List<Map<String, dynamic>> groupSchedules,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointed Job Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (_hasJobOrGroupScheduleOnDate(date, jobs, groupSchedules)) {
                  final jobsOnDate = _getJobsForDate(date, jobs);
                  final groupSchedulesOnDate = _getGroupSchedulesForDate(
                    date,
                    groupSchedules,
                  );

                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...jobsOnDate.asMap().entries.map((entry) {
                          final index = entry.key;
                          final color = _getJobColor(entry.value.jobId, index);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                        ...groupSchedulesOnDate.asMap().entries.map((entry) {
                          final index = entry.key + jobsOnDate.length;
                          final jobId =
                              (entry.value['jobId'] as String?) ??
                              'group-${entry.value.hashCode}';
                          final color = _getJobColor(jobId, index);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }
                return null;
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          if (_selectedDay != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jobs on ${_formatDate(_selectedDay!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._getJobsForDate(
                        _selectedDay!,
                        jobs,
                      ).asMap().entries.map((entry) {
                        final job = entry.value;
                        final color = _getJobColor(job.jobId, entry.key);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  job.jobTitle,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      ..._getGroupSchedulesForDate(
                        _selectedDay!,
                        groupSchedules,
                      ).asMap().entries.map((entry) {
                        final schedule = entry.value;
                        final index =
                            entry.key +
                            _getJobsForDate(_selectedDay!, jobs).length;
                        final jobId =
                            (schedule['jobId'] as String?) ??
                            'group-${schedule.hashCode}';
                        final color = _getJobColor(jobId, index);
                        final jobTitle =
                            (schedule['jobTitle'] as String?) ?? 'Group Job';
                        final groupName =
                            (schedule['groupName'] as String?) ?? 'Group';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$jobTitle ($groupName)',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _checkIfJobRated({
    required String workerId,
    required String applicationId,
  }) async {
    if (_ratedJobs.containsKey(applicationId)) {
      return _ratedJobs[applicationId] ?? false;
    }

    try {
      // Fetch application data to get landownerId and jobId
      final appRef = FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId);
      final appSnapshot = await appRef.get();
      final appData = appSnapshot.data() ?? <String, dynamic>{};

      final landownerId = (appData['landownerId'] as String?)?.trim() ?? '';
      final jobId = (appData['jobId'] as String?)?.trim() ?? '';

      if (landownerId.isEmpty || jobId.isEmpty) {
        if (mounted) {
          setState(() {
            _ratedJobs[applicationId] = false;
          });
        }
        return false;
      }

      final hasRating = await JobRepository.hasRatingForJob(
        fromUserId: workerId,
        toUserId: landownerId,
        jobId: jobId,
      );

      if (mounted) {
        setState(() {
          _ratedJobs[applicationId] = hasRating;
        });
      }

      return hasRating;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkIfGroupJobRated({
    required String workerId,
    required String groupApplicationId,
  }) async {
    if (_ratedJobs.containsKey(groupApplicationId)) {
      return _ratedJobs[groupApplicationId] ?? false;
    }

    try {
      final appRef = FirebaseFirestore.instance
          .collection('group_applications')
          .doc(groupApplicationId);
      final appSnapshot = await appRef.get();
      final appData = appSnapshot.data() ?? <String, dynamic>{};

      final landownerId = (appData['landownerId'] as String?)?.trim() ?? '';
      final jobId = (appData['jobId'] as String?)?.trim() ?? '';

      if (landownerId.isEmpty || jobId.isEmpty) {
        if (mounted) {
          setState(() {
            _ratedJobs[groupApplicationId] = false;
          });
        }
        return false;
      }

      final hasRating = await JobRepository.hasRatingForJob(
        fromUserId: workerId,
        toUserId: landownerId,
        jobId: jobId,
      );

      if (mounted) {
        setState(() {
          _ratedJobs[groupApplicationId] = hasRating;
        });
      }

      return hasRating;
    } catch (e) {
      return false;
    }
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
        item(Colors.greenAccent, 'Approved'),
        item(Colors.lightBlueAccent, 'Accepted'),
        item(Colors.orangeAccent, 'In Progress'),
        item(Colors.purpleAccent, 'Completed'),
      ],
    );
  }

  Future<void> _acceptGroupOffer({
    required String workerId,
    required String groupApplicationId,
  }) async {
    setState(() {
      _actionApplicationId = groupApplicationId;
    });

    try {
      // First, fetch the group application to check for conflicts
      final appSnapshot = await FirebaseFirestore.instance
          .collection('group_applications')
          .doc(groupApplicationId)
          .get();
      final appData = appSnapshot.data();

      if (appData == null) {
        throw StateError('Group application not found.');
      }

      final memberIds =
          ((appData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
              .map((id) => id.toString())
              .toList();
      final memberNames =
          ((appData['memberNames'] as List<dynamic>?) ?? const <dynamic>[])
              .map((name) => name.toString())
              .toList();
      final jobStartDate =
          (appData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final estimatedDays = ((appData['estimatedDays'] as num?) ?? 1).toInt();

      // Check for conflicts
      final conflictResult = await JobRepository.getGroupApplicationConflicts(
        memberIds: memberIds,
        memberNames: memberNames,
        jobStartDate: jobStartDate,
        jobEstimatedDays: estimatedDays,
      );

      if (!mounted) {
        return;
      }

      // If there are conflicts, show resolution dialog
      if (conflictResult.hasConflicts) {
        setState(() {
          _actionApplicationId = null;
        });

        await _showGroupAcceptanceConflictDialog(
          workerId: workerId,
          groupApplicationId: groupApplicationId,
          conflictResult: conflictResult,
          appData: appData,
        );
        return;
      }

      // No conflicts, proceed with normal acceptance
      await JobRepository.acceptGroupApplicationByCoordinator(
        coordinatorId: workerId,
        groupApplicationId: groupApplicationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Group offer accepted. Schedules created and overlapping approved offers for members were declined.',
          ),
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

  Future<void> _showGroupAcceptanceConflictDialog({
    required String workerId,
    required String groupApplicationId,
    required GroupConflictResult conflictResult,
    required Map<String, dynamic> appData,
  }) async {
    var selectedMemberIds = Set<String>.from(conflictResult.availableMembers);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Conflicting Members Detected'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The following members have scheduling conflicts and cannot be scheduled:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...conflictResult.conflictingMembers.map(
                      (conflict) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${conflict.memberName} - Conflict:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                '${conflict.conflictingJobTitle}\n'
                                '${conflict.conflictingStartDate.toString().split(' ')[0]} - '
                                '${conflict.conflictingEndDate.toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Members who can be scheduled:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...conflictResult.availableMembers.map((memberId) {
                      final memberNames =
                          ((appData['memberNames'] as List<dynamic>?) ??
                                  const <dynamic>[])
                              .map((name) => name.toString())
                              .toList();
                      final memberIds =
                          ((appData['memberIds'] as List<dynamic>?) ??
                                  const <dynamic>[])
                              .map((id) => id.toString())
                              .toList();
                      final memberIndex = memberIds.indexOf(memberId);
                      final memberName =
                          memberIndex >= 0 && memberIndex < memberNames.length
                          ? memberNames[memberIndex]
                          : 'Worker';
                      return CheckboxListTile(
                        value: selectedMemberIds.contains(memberId),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedMemberIds.add(memberId);
                            } else {
                              selectedMemberIds.remove(memberId);
                            }
                          });
                        },
                        title: Text(memberName),
                        dense: true,
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedMemberIds.isEmpty
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          _acceptGroupWithSelectedMembers(
                            workerId: workerId,
                            groupApplicationId: groupApplicationId,
                            memberIdsToAccept: selectedMemberIds.toList(),
                          );
                        },
                  child: const Text('Accept With Selected Members'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _acceptGroupWithSelectedMembers({
    required String workerId,
    required String groupApplicationId,
    required List<String> memberIdsToAccept,
  }) async {
    setState(() {
      _actionApplicationId = groupApplicationId;
    });

    try {
      // Accept with only the selected members
      await JobRepository.acceptGroupApplicationWithConflictResolution(
        coordinatorId: workerId,
        groupApplicationId: groupApplicationId,
        memberIdsToAccept: memberIdsToAccept,
        byLandowner: false,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Group offer accepted with selected members. Schedules created.',
          ),
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

  Future<void> _declineGroupOffer({
    required String workerId,
    required String groupApplicationId,
  }) async {
    setState(() {
      _actionApplicationId = groupApplicationId;
    });

    try {
      await JobRepository.declineGroupApplicationByCoordinator(
        coordinatorId: workerId,
        groupApplicationId: groupApplicationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group offer declined.')));
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

  Future<void> _acceptOffer({
    required String workerId,
    required String applicationId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Job Acceptance'),
          content: const Text(
            'If this job overlaps with your other approved offers, those overlapping offers will be declined automatically.\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Accept Job'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

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
          content: Text(
            'Job accepted. Only overlapping approved offers were declined.',
          ),
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
                final messenger = ScaffoldMessenger.of(this.context);
                final quillCount = int.tryParse(quillController.text.trim());
                if (quillCount == null || quillCount <= 0) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid quill count greater than zero.',
                      ),
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

                  Navigator.of(this.context).pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Daily progress recorded.')),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  messenger.showSnackBar(
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

  Future<void> _showGroupProgressDialog({
    required String workerId,
    required GroupJobApplicationRecord application,
  }) async {
    final quillController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Group Daily Progress'),
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
                  hintText: 'Any daily group update',
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
                final messenger = ScaffoldMessenger.of(this.context);
                final quillCount = int.tryParse(quillController.text.trim());
                if (quillCount == null || quillCount <= 0) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid quill count greater than zero.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await JobRepository.submitGroupDailyProgress(
                    workerId: workerId,
                    groupApplicationId: application.id,
                    quillCount: quillCount,
                    notes: notesController.text.trim(),
                  );

                  if (!mounted) {
                    return;
                  }

                  Navigator.of(this.context).pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Group daily progress recorded.'),
                    ),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  messenger.showSnackBar(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Completion'),
          content: const Text(
            'Are you sure you want to mark this job as completed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job marked as completed.')));

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        return;
      }

      await _showRatingDialog(workerId: workerId, applicationId: applicationId);
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

  Future<void> _markGroupCompleted({
    required String workerId,
    required String groupApplicationId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Completion'),
          content: const Text(
            'Are you sure you want to mark this group job as completed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _actionApplicationId = groupApplicationId;
    });

    try {
      await JobRepository.markGroupApplicationCompleted(
        workerId: workerId,
        groupApplicationId: groupApplicationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group job marked as completed.')),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        return;
      }

      await _showGroupRatingDialog(
        workerId: workerId,
        groupApplicationId: groupApplicationId,
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
    final jobId = appData['jobId'] as String? ?? '';
    final workerProfile = await AuthService.getCurrentUserProfile();
    final workerName = (workerProfile?['name'] as String?) ?? 'Worker';

    if (landownerId.trim().isEmpty || jobId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to submit rating because job details are missing.',
            ),
          ),
        );
      }
      return;
    }

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
                    final messenger = ScaffoldMessenger.of(this.context);
                    try {
                      await JobRepository.submitRating(
                        fromUserId: workerId,
                        fromUserName: workerName,
                        toUserId: landownerId,
                        toUserName: landownerName,
                        jobId: jobId,
                        rating: selectedRating,
                        feedback: ratingController.text.trim(),
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

  Future<void> _showGroupRatingDialog({
    required String workerId,
    required String groupApplicationId,
  }) async {
    final appRef = FirebaseFirestore.instance
        .collection('group_applications')
        .doc(groupApplicationId);
    final appSnapshot = await appRef.get();
    final appData = appSnapshot.data() ?? <String, dynamic>{};

    final landownerId = appData['landownerId'] as String? ?? '';
    final landownerName = appData['landownerName'] as String? ?? 'Landowner';
    final jobId = appData['jobId'] as String? ?? '';
    final workerProfile = await AuthService.getCurrentUserProfile();
    final workerName = (workerProfile?['name'] as String?) ?? 'Worker';

    if (landownerId.trim().isEmpty || jobId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to submit rating because group job details are missing.',
            ),
          ),
        );
      }
      return;
    }

    final alreadyRated = await JobRepository.hasRatingForJob(
      fromUserId: workerId,
      toUserId: landownerId,
      jobId: jobId,
    );
    if (alreadyRated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already rated this landowner.'),
          ),
        );
      }
      return;
    }

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
              title: const Text('Rate This Group Job'),
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
                    final messenger = ScaffoldMessenger.of(this.context);
                    try {
                      await JobRepository.submitRating(
                        fromUserId: workerId,
                        fromUserName: workerName,
                        toUserId: landownerId,
                        toUserName: landownerName,
                        jobId: jobId,
                        rating: selectedRating,
                        feedback: ratingController.text.trim(),
                      );

                      if (!mounted) {
                        return;
                      }

                      Navigator.of(this.context).pop();
                      setState(() {
                        _ratedJobs[groupApplicationId] = true;
                      });
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
                      const Icon(
                        Icons.fiber_manual_record,
                        size: 10,
                        color: Colors.blue,
                      ),
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

  Widget _buildGroupProgressHistory(String groupApplicationId) {
    return StreamBuilder<List<TaskProgressRecord>>(
      stream: JobRepository.streamProgressForGroupApplication(
        groupApplicationId,
      ),
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
              'No group progress entries yet.',
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
                      const Icon(
                        Icons.fiber_manual_record,
                        size: 10,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatDate(record.progressDate)} - ${record.workerName}: ${record.quillCount} quills${record.notes.isEmpty ? '' : ' (${record.notes})'}',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF0F1B18), Color(0xFF1D3A2F)]
        : const [Colors.greenAccent, Colors.lightGreenAccent];
    final shellSurfaceColor = isDark ? const Color(0xFF101917) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: shellTopColors,
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
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  _buildFlowLegend(),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: shellSurfaceColor,
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
                        stream: JobRepository.streamApplicationsForWorker(
                          workerId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'Unable to load approved jobs right now.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          final approvedJobs =
                              snapshot.data ??
                              const <WorkerApplicationRecord>[];

                          return StreamBuilder<List<GroupJobApplicationRecord>>(
                            stream:
                                JobRepository.streamGroupApplicationsForWorker(
                                  workerId,
                                ),
                            builder: (context, groupSnapshot) {
                              final groupApplications =
                                  groupSnapshot.data ??
                                  const <GroupJobApplicationRecord>[];

                              // Fetch group job schedules for calendar
                              return StreamBuilder<List<Map<String, dynamic>>>(
                                stream:
                                    JobRepository.streamGroupJobSchedulesForWorker(
                                      workerId,
                                    ),
                                builder: (context, groupSchedulesSnapshot) {
                                  final groupSchedules =
                                      groupSchedulesSnapshot.data ??
                                      const <Map<String, dynamic>>[];

                                  if (approvedJobs.isEmpty &&
                                      groupApplications.isEmpty &&
                                      groupSchedules.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No approved jobs yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }

                                  final individualCards = approvedJobs
                                      .map((job) {
                                        final isBusy =
                                            _actionApplicationId == job.id;
                                        final statusColor = _statusColor(
                                          job.status,
                                        );
                                        return Card(
                                          elevation: 4,
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        job.jobTitle,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(job.location),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    const Icon(
                                                      Icons.payments,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'LKR ${job.paymentRate.toStringAsFixed(0)}',
                                                    ),
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
                                                  'Estimated End Date: ${_formatDate(_jobEndDate(job))}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.blueGrey,
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
                                                if (job.status ==
                                                    'approved') ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _decisionWindowLabel(
                                                      job.decisionDeadline,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.deepOrange,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _applicationStatusLabel(
                                                      job.status,
                                                    ),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (job.status ==
                                                    'approved') ...[
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: isBusy
                                                              ? null
                                                              : () => _declineOffer(
                                                                  workerId:
                                                                      workerId,
                                                                  applicationId:
                                                                      job.id,
                                                                ),
                                                          style:
                                                              OutlinedButton.styleFrom(
                                                                foregroundColor:
                                                                    Colors.red,
                                                              ),
                                                          child: const Text(
                                                            'Decline',
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: isBusy
                                                              ? null
                                                              : () => _acceptOffer(
                                                                  workerId:
                                                                      workerId,
                                                                  applicationId:
                                                                      job.id,
                                                                ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                          child: isBusy
                                                              ? const SizedBox(
                                                                  height: 18,
                                                                  width: 18,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                )
                                                              : const Text(
                                                                  'Accept',
                                                                ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (job.status == 'accepted' ||
                                                    job.status ==
                                                        'in_progress') ...[
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () =>
                                                          _showProgressDialog(
                                                            workerId: workerId,
                                                            job: job,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.edit_note,
                                                      ),
                                                      label: const Text(
                                                        'Record Daily Progress',
                                                      ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.blue,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: OutlinedButton.icon(
                                                      onPressed: isBusy
                                                          ? null
                                                          : () =>
                                                                _markCompleted(
                                                                  workerId:
                                                                      workerId,
                                                                  applicationId:
                                                                      job.id,
                                                                ),
                                                      icon: const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                      ),
                                                      label: isBusy
                                                          ? const Text(
                                                              'Updating...',
                                                            )
                                                          : const Text(
                                                              'Mark Job Completed',
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                                if (job.status ==
                                                    'completed') ...[
                                                  const SizedBox(height: 12),
                                                  FutureBuilder<bool>(
                                                    future: _checkIfJobRated(
                                                      workerId: workerId,
                                                      applicationId: job.id,
                                                    ),
                                                    builder: (context, snapshot) {
                                                      final alreadyRated =
                                                          snapshot.data ??
                                                          false;
                                                      return SizedBox(
                                                        width: double.infinity,
                                                        child: Tooltip(
                                                          message: alreadyRated
                                                              ? 'You have already rated this landowner for this job'
                                                              : '',
                                                          child: OutlinedButton.icon(
                                                            onPressed:
                                                                alreadyRated
                                                                ? null
                                                                : () => _showRatingDialog(
                                                                    workerId:
                                                                        workerId,
                                                                    applicationId:
                                                                        job.id,
                                                                  ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .star_outline,
                                                            ),
                                                            label: Text(
                                                              alreadyRated
                                                                  ? 'Rating Submitted'
                                                                  : 'Rate Landowner',
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                                if (job.status == 'accepted' ||
                                                    job.status ==
                                                        'in_progress' ||
                                                    job.status ==
                                                        'completed') ...[
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'Recent Daily Progress',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  _buildProgressHistory(job.id),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(growable: false);

                                  final groupCards = groupApplications
                                      .map((application) {
                                        final statusColor = _statusColor(
                                          application.status,
                                        );
                                        final isCoordinator =
                                            application.coordinatorId ==
                                            workerId;
                                        final isBusy =
                                            _actionApplicationId ==
                                            application.id;
                                        return Card(
                                          elevation: 4,
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.groups,
                                                      color: Colors.brown,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        application.jobTitle,
                                                        style: const TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Group: ${application.groupName}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Landowner: ${application.landownerName}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Members: ${application.memberIds.length}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _groupStatusLabel(
                                                      application.status,
                                                    ),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _groupStatusLabel(
                                                    application.status,
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (isCoordinator &&
                                                    application.status ==
                                                        'approved') ...[
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: isBusy
                                                              ? null
                                                              : () => _declineGroupOffer(
                                                                  workerId:
                                                                      workerId,
                                                                  groupApplicationId:
                                                                      application
                                                                          .id,
                                                                ),
                                                          style:
                                                              OutlinedButton.styleFrom(
                                                                foregroundColor:
                                                                    Colors.red,
                                                              ),
                                                          child: const Text(
                                                            'Decline Group',
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: isBusy
                                                              ? null
                                                              : () => _acceptGroupOffer(
                                                                  workerId:
                                                                      workerId,
                                                                  groupApplicationId:
                                                                      application
                                                                          .id,
                                                                ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                          child: isBusy
                                                              ? const SizedBox(
                                                                  height: 18,
                                                                  width: 18,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                )
                                                              : const Text(
                                                                  'Accept Group',
                                                                ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (application.status ==
                                                        'accepted' ||
                                                    application.status ==
                                                        'in_progress') ...[
                                                  const SizedBox(height: 10),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () =>
                                                          _showGroupProgressDialog(
                                                            workerId: workerId,
                                                            application:
                                                                application,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.edit_note,
                                                      ),
                                                      label: const Text(
                                                        'Record Group Daily Progress',
                                                      ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.blue,
                                                          ),
                                                    ),
                                                  ),
                                                  if (isCoordinator) ...[
                                                    const SizedBox(height: 10),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: OutlinedButton.icon(
                                                        onPressed: isBusy
                                                            ? null
                                                            : () => _markGroupCompleted(
                                                                workerId:
                                                                    workerId,
                                                                groupApplicationId:
                                                                    application
                                                                        .id,
                                                              ),
                                                        icon: const Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                        ),
                                                        label: isBusy
                                                            ? const Text(
                                                                'Updating...',
                                                              )
                                                            : const Text(
                                                                'Mark Group Job Completed',
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                                if (application.status ==
                                                    'completed') ...[
                                                  const SizedBox(height: 12),
                                                  FutureBuilder<bool>(
                                                    future:
                                                        _checkIfGroupJobRated(
                                                          workerId: workerId,
                                                          groupApplicationId:
                                                              application.id,
                                                        ),
                                                    builder: (context, snapshot) {
                                                      final alreadyRated =
                                                          snapshot.data ??
                                                          false;
                                                      return SizedBox(
                                                        width: double.infinity,
                                                        child: Tooltip(
                                                          message: alreadyRated
                                                              ? 'You have already rated this landowner for this job'
                                                              : '',
                                                          child: OutlinedButton.icon(
                                                            onPressed:
                                                                alreadyRated
                                                                ? null
                                                                : () => _showGroupRatingDialog(
                                                                    workerId:
                                                                        workerId,
                                                                    groupApplicationId:
                                                                        application
                                                                            .id,
                                                                  ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .star_outline,
                                                            ),
                                                            label: Text(
                                                              alreadyRated
                                                                  ? 'Rating Submitted'
                                                                  : 'Rate Landowner',
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                                if (application.status ==
                                                        'accepted' ||
                                                    application.status ==
                                                        'in_progress' ||
                                                    application.status ==
                                                        'completed') ...[
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'Recent Group Progress',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  _buildGroupProgressHistory(
                                                    application.id,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(growable: false);

                                  Widget individualSection = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (individualCards.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 16),
                                          child: Text(
                                            'No individual applications.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      else
                                        ...individualCards,
                                    ],
                                  );

                                  Widget groupSection = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (groupCards.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 16),
                                          child: Text(
                                            'No group applications.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      else
                                        ...groupCards,
                                    ],
                                  );

                                  final selectedSection =
                                      _showIndividualApplications
                                      ? individualSection
                                      : groupSection;

                                  return ListView(
                                    padding: const EdgeInsets.all(20),
                                    children: [
                                      _buildJobCalendar(
                                        approvedJobs,
                                        groupSchedules,
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                if (!_showIndividualApplications) {
                                                  setState(() {
                                                    _showIndividualApplications =
                                                        true;
                                                  });
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    _showIndividualApplications
                                                    ? Colors.green.withValues(
                                                        alpha: 0.15,
                                                      )
                                                    : null,
                                                side: BorderSide(
                                                  color:
                                                      _showIndividualApplications
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                              ),
                                              child: const Text(
                                                'Individual Applications',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                if (_showIndividualApplications) {
                                                  setState(() {
                                                    _showIndividualApplications =
                                                        false;
                                                  });
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    !_showIndividualApplications
                                                    ? Colors.green.withValues(
                                                        alpha: 0.15,
                                                      )
                                                    : null,
                                                side: BorderSide(
                                                  color:
                                                      !_showIndividualApplications
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                              ),
                                              child: const Text(
                                                'Group Applications',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      selectedSection,
                                    ],
                                  );
                                },
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
  final _groupNameController = TextEditingController();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isCreatingGroup = false;
  String _currentUserId = '';
  String? _groupNameErrorText;

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
      _currentUserId = AuthService.currentUserId ?? '';
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

  String _readableError(Object error) {
    final text = error.toString();
    if (text.contains('FIRESTORE') &&
        text.contains('INTERNAL ASSERTION FAILED')) {
      return 'Group action failed due to a web database issue. Please refresh and try again.';
    }
    if (text.contains('already in the group as coordinator')) {
      return 'You are already in the group as coordinator.';
    }
    if (text.contains('already in the group')) {
      return 'This worker is already in the group.';
    }
    if (text.contains('Only the group coordinator can add members')) {
      return 'Only the group coordinator can add members.';
    }
    if (text.contains('No worker account found for this phone number')) {
      return 'No worker account found for this phone number.';
    }
    if (text.contains('Dart exception thrown from converted Future')) {
      return 'Action failed on web runtime. Please try again.';
    }
    return text.replaceFirst('Bad state: ', '').trim();
  }

  Future<void> _createGroup() async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }

    final workerName = _nameController.text.trim().isEmpty
        ? 'Worker'
        : _nameController.text.trim();
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      setState(() {
        _groupNameErrorText = 'Group name is required.';
      });
      return;
    }

    if (_groupNameErrorText != null) {
      setState(() {
        _groupNameErrorText = null;
      });
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      await JobRepository.createWorkerGroup(
        coordinatorId: workerId,
        coordinatorName: workerName,
        groupName: groupName,
      );

      if (!mounted) {
        return;
      }

      _groupNameController.clear();
      setState(() {
        _groupNameErrorText = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Worker group created.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = _readableError(error);
      if (message.contains('already taken')) {
        setState(() {
          _groupNameErrorText = 'This name is already taken.';
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  Future<void> _showAddMemberDialog(WorkerGroupRecord group) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      return;
    }

    final memberPhoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Group Member'),
          content: TextField(
            controller: memberPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Worker Phone Number',
              hintText: 'e.g. +94771234567',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await JobRepository.addMemberToGroupByPhone(
                    groupId: group.id,
                    coordinatorId: workerId,
                    phoneNumber: memberPhoneController.text.trim(),
                  );

                  if (!mounted) {
                    return;
                  }

                  Navigator.of(context).pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Member added to group.')),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }

                  messenger.showSnackBar(
                    SnackBar(content: Text(_readableError(error))),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteGroup(WorkerGroupRecord group) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Group'),
          content: Text(
            'Are you sure you want to delete "${group.groupName}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await JobRepository.deleteWorkerGroup(
        groupId: group.id,
        coordinatorId: workerId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_readableError(error))));
    }
  }

  Future<void> _confirmRemoveMember({
    required WorkerGroupRecord group,
    required String memberId,
    required String memberName,
  }) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      return;
    }

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Member'),
          content: Text('Remove $memberName from "${group.groupName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    try {
      await JobRepository.removeMemberFromGroup(
        groupId: group.id,
        coordinatorId: workerId,
        memberWorkerId: memberId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed from group.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_readableError(error))));
    }
  }

  Future<void> _confirmExitGroup(WorkerGroupRecord group) async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) {
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Exit Group'),
          content: Text('Do you want to exit "${group.groupName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    if (shouldExit != true) {
      return;
    }

    try {
      await JobRepository.leaveGroup(groupId: group.id, workerId: workerId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You exited the group.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_readableError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF0E171A), Color(0xFF15363A)]
        : const [Colors.blueAccent, Colors.lightBlueAccent];
    final inputFill = isDark ? const Color(0xFF1A262A) : Colors.grey.shade50;
    final groupTileColor = isDark
        ? const Color(0xFF14201D)
        : Colors.grey.shade50;
    final groupBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: shellTopColors,
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
                      style: TextStyle(fontSize: 16, color: Colors.white70),
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
                                fillColor: inputFill,
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
                                fillColor: inputFill,
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
                                fillColor: inputFill,
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
                                fillColor: inputFill,
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
                    const SizedBox(height: 20),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Worker Groups',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _groupNameController,
                              onChanged: (_) {
                                if (_groupNameErrorText != null) {
                                  setState(() {
                                    _groupNameErrorText = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'New Group Name',
                                hintText: 'e.g. Kandy Peeling Team',
                                errorText: _groupNameErrorText,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isCreatingGroup
                                    ? null
                                    : _createGroup,
                                icon: _isCreatingGroup
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.group_add),
                                label: const Text('Create Group'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Builder(
                              builder: (context) {
                                final currentWorkerId =
                                    AuthService.currentUserId;
                                if (currentWorkerId == null) {
                                  return const Text(
                                    'Please sign in to manage groups.',
                                  );
                                }

                                return StreamBuilder<List<WorkerGroupRecord>>(
                                  stream: JobRepository.streamGroupsForWorker(
                                    currentWorkerId,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return const Text(
                                        'Unable to load groups right now.',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      );
                                    }

                                    final groups =
                                        snapshot.data ??
                                        const <WorkerGroupRecord>[];
                                    if (groups.isEmpty) {
                                      return const Text(
                                        'No groups yet. Create one to start coordinating members.',
                                        style: TextStyle(color: Colors.grey),
                                      );
                                    }

                                    return Column(
                                      children: groups
                                          .map((group) {
                                            final isCoordinator =
                                                group.coordinatorId ==
                                                currentWorkerId;
                                            final memberEntries = group.members
                                                .map((member) {
                                                  final memberId =
                                                      (member['workerId']
                                                          as String?) ??
                                                      '';
                                                  final memberName =
                                                      (member['workerName']
                                                          as String?) ??
                                                      'Worker';
                                                  return MapEntry(
                                                    memberId,
                                                    memberName,
                                                  );
                                                })
                                                .where(
                                                  (entry) =>
                                                      entry.key.isNotEmpty,
                                                )
                                                .toList(growable: false);
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                top: 10,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: groupTileColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: groupBorderColor,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          group.groupName,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isCoordinator
                                                              ? Colors.blue
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    )
                                                              : Colors.green
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                999,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          isCoordinator
                                                              ? 'Coordinator'
                                                              : 'Member',
                                                          style: TextStyle(
                                                            color: isCoordinator
                                                                ? Colors.blue
                                                                : Colors.green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Members: ${group.memberIds.length}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  if (memberEntries
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: memberEntries
                                                          .map((entry) {
                                                            final isSelf =
                                                                entry.key ==
                                                                currentWorkerId;
                                                            return Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .blue
                                                                    .withValues(
                                                                      alpha:
                                                                          0.08,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      999,
                                                                    ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    entry.value,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                  if (isCoordinator &&
                                                                      !isSelf) ...[
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    GestureDetector(
                                                                      onTap: () => _confirmRemoveMember(
                                                                        group:
                                                                            group,
                                                                        memberId:
                                                                            entry.key,
                                                                        memberName:
                                                                            entry.value,
                                                                      ),
                                                                      child: const Icon(
                                                                        Icons
                                                                            .close,
                                                                        size:
                                                                            16,
                                                                        color: Colors
                                                                            .red,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            );
                                                          })
                                                          .toList(
                                                            growable: false,
                                                          ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _confirmExitGroup(
                                                            group,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.exit_to_app,
                                                      ),
                                                      label: Text(
                                                        isCoordinator
                                                            ? 'Exit Group (Transfer Coordinator)'
                                                            : 'Exit Group',
                                                      ),
                                                    ),
                                                  ),
                                                  if (isCoordinator) ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton.icon(
                                                            onPressed: () =>
                                                                _showAddMemberDialog(
                                                                  group,
                                                                ),
                                                            icon: const Icon(
                                                              Icons.person_add,
                                                            ),
                                                            label: const Text(
                                                              'Add Member',
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: OutlinedButton.icon(
                                                            onPressed: () =>
                                                                _confirmDeleteGroup(
                                                                  group,
                                                                ),
                                                            style: OutlinedButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors.red,
                                                              side:
                                                                  const BorderSide(
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                            ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                            ),
                                                            label: const Text(
                                                              'Delete Group',
                                                            ),
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
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ratings & Reviews',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Feedback from landowners appears here.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 14),
                            if (_currentUserId.isEmpty)
                              const Text(
                                'Unable to load ratings right now.',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              ProfileReviewsSection(
                                userId: _currentUserId,
                                summaryTitle: 'Overall landowner feedback',
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
