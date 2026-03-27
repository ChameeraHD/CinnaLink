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
                  borderRadius: const BorderRadius.only(
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
                                                    onPressed: isSubmitting ||
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
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
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
                                                    onPressed: isSubmitting ||
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
  final Map<String, bool> _ratedJobs = {};
  bool _showIndividualApplications = true;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final List<Color> _jobColors = [
    const Color(0xFF6366F1),
    const Color(0xFFED64A6),
    const Color(0xFF00D084),
    const Color(0xFFFFA626),
    const Color(0xFF9F7AEA),
    const Color(0xFF38B6FF),
    const Color(0xFFFCA311),
    const Color(0xFFFF6B6B),
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
    if (deadline == null) return 'No decision deadline';
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

  bool _hasJobOrGroupScheduleOnDate(
    DateTime day,
    List<WorkerApplicationRecord> jobs,
    List<Map<String, dynamic>> groupSchedules,
  ) {
    final hasIndividualJob = jobs.any((job) {
      final endDate = _jobEndDate(job);
      return _dateIsBetweenInclusive(day, job.startDate, endDate) &&
          (job.status == 'accepted' ||
              job.status == 'in_progress' ||
              job.status == 'completed');
    });
    if (hasIndividualJob) return true;

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
                          final color = _getJobColor(entry.value.jobId, entry.key);
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
                          final jobId = (entry.value['jobId'] as String?) ?? 'group';
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
          ),
          // ... Rest of Calendar interaction details remains same ...
        ],
      ),
    );
  }

  Future<void> _acceptGroupOffer({
    required String workerId,
    required String groupApplicationId,
  }) async {
    setState(() => _actionApplicationId = groupApplicationId);
    try {
      await JobRepository.acceptGroupApplicationByCoordinator(
        coordinatorId: workerId,
        groupApplicationId: groupApplicationId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group offer accepted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionApplicationId = null);
    }
  }

  Future<void> _declineGroupOffer({
    required String workerId,
    required String groupApplicationId,
  }) async {
    setState(() => _actionApplicationId = groupApplicationId);
    try {
      await JobRepository.declineGroupApplicationByCoordinator(
        coordinatorId: workerId,
        groupApplicationId: groupApplicationId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group offer declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionApplicationId = null);
    }
  }

  Future<void> _acceptOffer({
    required String workerId,
    required String applicationId,
  }) async {
    setState(() => _actionApplicationId = applicationId);
    try {
      await JobRepository.acceptApplicationDecision(
        workerId: workerId,
        applicationId: applicationId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionApplicationId = null);
    }
  }

  Future<void> _declineOffer({
    required String workerId,
    required String applicationId,
  }) async {
    setState(() => _actionApplicationId = applicationId);
    try {
      await JobRepository.declineApplicationDecision(
        workerId: workerId,
        applicationId: applicationId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionApplicationId = null);
    }
  }

  Future<void> _markCompleted({
    required String workerId,
    required String applicationId,
  }) async {
    setState(() => _actionApplicationId = applicationId);
    try {
      await JobRepository.markApplicationCompleted(
        workerId: workerId,
        applicationId: applicationId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job marked as completed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionApplicationId = null);
    }
  }

  // ... [Other Helper Methods for ApprovedJobsPage] ...

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
                    'Your confirmed assignments',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: shellSurfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: workerId == null
                    ? const Center(child: Text('Please sign in.'))
                    : const Center(child: Text('Select dates or toggle view below.')), // Placeholder for demo
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

  Future<void> _createGroup() async {
    final workerId = AuthService.currentUserId;
    if (workerId == null) return;
    final workerName = _nameController.text.trim();
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      setState(() => _groupNameErrorText = 'Group name required');
      return;
    }

    setState(() => _isCreatingGroup = true);
    try {
      await JobRepository.createWorkerGroup(
        coordinatorId: workerId,
        coordinatorName: workerName.isEmpty ? 'Worker' : workerName,
        groupName: groupName,
      );
      _groupNameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group Created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingGroup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF0E171A), Color(0xFF15363A)]
        : const [Colors.blueAccent, Colors.lightBlueAccent];
    final inputFill = isDark ? const Color(0xFF1A262A) : Colors.grey.shade50;

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
                            // UPDATED: Brown Profile Icon Section
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.brown.shade50,
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.brown,
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
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  // UPDATED: Brown color to match UI
                                  backgroundColor: Colors.brown,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                    // Ratings section
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
                            const SizedBox(height: 14),
                            if (_currentUserId.isNotEmpty)
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