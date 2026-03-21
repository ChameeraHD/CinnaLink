import 'package:cloud_firestore/cloud_firestore.dart';

class JobRecord {
  JobRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.jobType,
    required this.paymentRate,
    required this.requiredWorkers,
    required this.estimatedDays,
    required this.startDate,
    required this.status,
    required this.landownerId,
    required this.landownerName,
    required this.applicantCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String jobType;
  final double paymentRate;
  final int requiredWorkers;
  final int estimatedDays;
  final DateTime startDate;
  final String status;
  final String landownerId;
  final String landownerName;
  final int applicantCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory JobRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return JobRecord(
      id: snapshot.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      jobType: (data['jobType'] as String?) ?? '',
      paymentRate: ((data['paymentRate'] as num?) ?? 0).toDouble(),
      requiredWorkers: ((data['requiredWorkers'] as num?) ?? 0).toInt(),
      estimatedDays: ((data['estimatedDays'] as num?) ?? 1).toInt(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: (data['status'] as String?) ?? 'open',
      landownerId: (data['landownerId'] as String?) ?? '',
      landownerName: (data['landownerName'] as String?) ?? 'Unknown landowner',
      applicantCount: ((data['applicantCount'] as num?) ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class WorkerApplicationRecord {
  WorkerApplicationRecord({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.location,
    required this.paymentRate,
    required this.startDate,
    required this.estimatedDays,
    required this.status,
    required this.landownerName,
    required this.decisionDeadline,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String workerId;
  final String workerName;
  final String workerPhone;
  final String location;
  final double paymentRate;
  final DateTime startDate;
  final int estimatedDays;
  final String status;
  final String landownerName;
  final DateTime? decisionDeadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WorkerApplicationRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return WorkerApplicationRecord(
      id: snapshot.id,
      jobId: (data['jobId'] as String?) ?? '',
      jobTitle: (data['jobTitle'] as String?) ?? '',
      workerId: (data['workerId'] as String?) ?? '',
      workerName: (data['workerName'] as String?) ?? 'Unknown worker',
      workerPhone: (data['workerPhone'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      paymentRate: ((data['paymentRate'] as num?) ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedDays: ((data['estimatedDays'] as num?) ?? 1).toInt(),
      status: (data['status'] as String?) ?? 'submitted',
      landownerName: (data['landownerName'] as String?) ?? 'Unknown landowner',
      decisionDeadline: (data['decisionDeadline'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class TaskProgressRecord {
  TaskProgressRecord({
    required this.id,
    required this.jobId,
    required this.applicationId,
    required this.groupApplicationId,
    required this.workerId,
    required this.workerName,
    required this.quillCount,
    required this.notes,
    required this.progressDate,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String applicationId;
  final String groupApplicationId;
  final String workerId;
  final String workerName;
  final int quillCount;
  final String notes;
  final DateTime progressDate;
  final DateTime? createdAt;

  factory TaskProgressRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return TaskProgressRecord(
      id: snapshot.id,
      jobId: (data['jobId'] as String?) ?? '',
      applicationId: (data['applicationId'] as String?) ?? '',
      groupApplicationId: (data['groupApplicationId'] as String?) ?? '',
      workerId: (data['workerId'] as String?) ?? '',
      workerName: (data['workerName'] as String?) ?? 'Unknown worker',
      quillCount: ((data['quillCount'] as num?) ?? 0).toInt(),
      notes: (data['notes'] as String?) ?? '',
      progressDate:
          (data['progressDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class RatingRecord {
  RatingRecord({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserRole,
    required this.toUserId,
    required this.toUserName,
    required this.toUserRole,
    required this.jobId,
    required this.rating,
    required this.feedback,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserRole;
  final String toUserId;
  final String toUserName;
  final String toUserRole;
  final String jobId;
  final double rating;
  final String feedback;
  final DateTime? createdAt;

  factory RatingRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return RatingRecord(
      id: snapshot.id,
      fromUserId: (data['fromUserId'] as String?) ?? '',
      fromUserName: (data['fromUserName'] as String?) ?? 'User',
      fromUserRole: (data['fromUserRole'] as String?) ?? '',
      toUserId: (data['toUserId'] as String?) ?? '',
      toUserName: (data['toUserName'] as String?) ?? 'User',
      toUserRole: (data['toUserRole'] as String?) ?? '',
      jobId: (data['jobId'] as String?) ?? '',
      rating: ((data['rating'] as num?) ?? 0).toDouble(),
      feedback: (data['feedback'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class WorkerGroupRecord {
  WorkerGroupRecord({
    required this.id,
    required this.groupName,
    required this.coordinatorId,
    required this.coordinatorName,
    required this.memberIds,
    required this.members,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String groupName;
  final String coordinatorId;
  final String coordinatorName;
  final List<String> memberIds;
  final List<Map<String, dynamic>> members;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WorkerGroupRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawMemberIds = (data['memberIds'] as List<dynamic>?) ?? const [];
    final rawMembers = (data['members'] as List<dynamic>?) ?? const [];

    return WorkerGroupRecord(
      id: snapshot.id,
      groupName: (data['groupName'] as String?) ?? 'Unnamed Group',
      coordinatorId: (data['coordinatorId'] as String?) ?? '',
      coordinatorName: (data['coordinatorName'] as String?) ?? 'Coordinator',
      memberIds: rawMemberIds
          .map((id) => id.toString())
          .toList(growable: false),
      members: rawMembers
          .whereType<Map>()
          .map(
            (member) =>
                member.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false),
      status: (data['status'] as String?) ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class GroupJobApplicationRecord {
  GroupJobApplicationRecord({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.groupId,
    required this.groupName,
    required this.coordinatorId,
    required this.coordinatorName,
    required this.landownerId,
    required this.landownerName,
    required this.memberIds,
    required this.memberNames,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String groupId;
  final String groupName;
  final String coordinatorId;
  final String coordinatorName;
  final String landownerId;
  final String landownerName;
  final List<String> memberIds;
  final List<String> memberNames;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GroupJobApplicationRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawMemberIds = (data['memberIds'] as List<dynamic>?) ?? const [];
    final rawMemberNames = (data['memberNames'] as List<dynamic>?) ?? const [];
    final rawMembers = (data['members'] as List<dynamic>?) ?? const [];
    final fallbackNames = rawMembers
        .whereType<Map>()
        .map((member) => member['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final memberNames = rawMemberNames
        .map((name) => name.toString().trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    return GroupJobApplicationRecord(
      id: snapshot.id,
      jobId: (data['jobId'] as String?) ?? '',
      jobTitle: (data['jobTitle'] as String?) ?? '',
      groupId: (data['groupId'] as String?) ?? '',
      groupName: (data['groupName'] as String?) ?? 'Unnamed Group',
      coordinatorId: (data['coordinatorId'] as String?) ?? '',
      coordinatorName: (data['coordinatorName'] as String?) ?? 'Coordinator',
      landownerId: (data['landownerId'] as String?) ?? '',
      landownerName: (data['landownerName'] as String?) ?? 'Unknown landowner',
      memberIds: rawMemberIds.map((id) => id.toString()).toList(growable: false),
      memberNames: memberNames.isNotEmpty ? memberNames : fallbackNames,
      status: (data['status'] as String?) ?? 'submitted',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class JobRepository {
  JobRepository._();

  static const Duration _approvalDecisionWindow = Duration(hours: 24);

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('jobs');

  static CollectionReference<Map<String, dynamic>>
  get _applicationsCollection => _firestore.collection('applications');

  static CollectionReference<Map<String, dynamic>> get _schedulesCollection =>
      _firestore.collection('schedules');

  static CollectionReference<Map<String, dynamic>>
  get _taskProgressCollection => _firestore.collection('task_progress');

  static CollectionReference<Map<String, dynamic>> get _ratingsCollection =>
      _firestore.collection('ratings');

  static CollectionReference<Map<String, dynamic>>
  get _workerGroupsCollection => _firestore.collection('worker_groups');

  static CollectionReference<Map<String, dynamic>>
  get _groupApplicationsCollection =>
      _firestore.collection('group_applications');

  static DateTime _decisionDeadlineFromNow() {
    return DateTime.now().add(_approvalDecisionWindow);
  }

  static bool _isExpiredDecision(DateTime? decisionDeadline) {
    if (decisionDeadline == null) {
      return false;
    }
    return decisionDeadline.isBefore(DateTime.now());
  }

  static String _scheduleDateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime _inclusiveEndDate(DateTime startDate, int estimatedDays) {
    final inclusiveDays = estimatedDays > 0 ? estimatedDays - 1 : 0;
    return startDate.add(Duration(days: inclusiveDays));
  }

  static bool _rangesOverlap({
    required DateTime firstStart,
    required DateTime firstEnd,
    required DateTime secondStart,
    required DateTime secondEnd,
  }) {
    return !firstStart.isAfter(secondEnd) && !firstEnd.isBefore(secondStart);
  }

  static Future<bool> _hasScheduleRangeConflict({
    required String workerId,
    required DateTime startDate,
    required int estimatedDays,
  }) async {
    final existingSchedules = await _schedulesCollection
        .where('workerId', isEqualTo: workerId)
        .get();

    final selectedEndDate = _inclusiveEndDate(startDate, estimatedDays);

    for (final doc in existingSchedules.docs) {
      final data = doc.data();
      final status = (data['status'] as String?) ?? '';
      if (status != 'accepted' && status != 'in_progress') {
        continue;
      }

      final existingStartDate =
          (data['startDate'] as Timestamp?)?.toDate() ?? startDate;
      final existingEstimatedDays = ((data['estimatedDays'] as num?) ?? 1).toInt();
      final existingEndDate =
          _inclusiveEndDate(existingStartDate, existingEstimatedDays);

      final overlaps = _rangesOverlap(
        firstStart: startDate,
        firstEnd: selectedEndDate,
        secondStart: existingStartDate,
        secondEnd: existingEndDate,
      );

      if (overlaps) {
        return true;
      }
    }

    return false;
  }

  static Future<bool> _hasScheduleConflict({
    required String workerId,
    required DateTime date,
  }) async {
    final dateKey = _scheduleDateKey(date);
    final conflictQuery = await _schedulesCollection
        .where('workerId', isEqualTo: workerId)
        .where('scheduleDateKey', isEqualTo: dateKey)
        .where('status', whereIn: ['accepted', 'in_progress'])
        .limit(1)
        .get();
    return conflictQuery.docs.isNotEmpty;
  }

  static Future<void> createJob({
    required String landownerId,
    required String landownerName,
    required String title,
    required String description,
    required String location,
    required String jobType,
    required double paymentRate,
    required int requiredWorkers,
    required int estimatedDays,
    required DateTime startDate,
    required String phone,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _jobsCollection.add({
      'landownerId': landownerId,
      'landownerName': landownerName,
      'title': title,
      'description': description,
      'location': location,
      'jobType': jobType,
      'paymentRate': paymentRate,
      'requiredWorkers': requiredWorkers,
      'phone': phone,
      'estimatedDays': estimatedDays,
      'startDate': Timestamp.fromDate(startDate),
      'status': 'open',
      'applicantCount': 0,
      'totalQuillCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static Stream<int> streamTotalQuillCountForJob(String jobId) {
    return _taskProgressCollection
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<int>(
            0,
            (total, doc) =>
                total + (((doc.data()['quillCount'] as num?) ?? 0).toInt()),
          ),
        );
  }

  static Stream<List<TaskProgressRecord>> streamProgressForApplication(
    String applicationId,
  ) {
    return _taskProgressCollection
        .where('applicationId', isEqualTo: applicationId)
        .snapshots()
        .map(
          (snapshot) {
            final records = snapshot.docs
                .map(TaskProgressRecord.fromSnapshot)
                .toList(growable: false);
            // Sort by createdAt descending in code (avoids needing composite Firestore index)
            records.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            return records;
          },
        );
  }

  static Stream<List<TaskProgressRecord>> streamProgressForGroupApplication(
    String groupApplicationId,
  ) {
    return _taskProgressCollection
        .where('groupApplicationId', isEqualTo: groupApplicationId)
        .snapshots()
        .map(
          (snapshot) {
            final records = snapshot.docs
                .map(TaskProgressRecord.fromSnapshot)
                .toList(growable: false);
            records.sort((a, b) =>
                (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            return records;
          },
        );
  }

  static Stream<int> streamTotalQuillCountForGroupApplication(
    String groupApplicationId,
  ) {
    return _taskProgressCollection
        .where('groupApplicationId', isEqualTo: groupApplicationId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<int>(
            0,
            (total, doc) =>
                total + (((doc.data()['quillCount'] as num?) ?? 0).toInt()),
          ),
        );
  }

  static Stream<List<TaskProgressRecord>> streamProgressForJob(String jobId) {
    return _taskProgressCollection
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map(
          (snapshot) {
            final records = snapshot.docs
                .map(TaskProgressRecord.fromSnapshot)
                .toList(growable: false);
            // Sort by createdAt descending in code (avoids needing composite Firestore index)
            records.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            return records;
          },
        );
  }

  static Stream<List<JobRecord>> streamOpenJobs() {
    return _jobsCollection.where('status', isEqualTo: 'open').snapshots().map((
      snapshot,
    ) {
      final jobs = snapshot.docs
          .map(JobRecord.fromSnapshot)
          .toList(growable: true);

      jobs.sort((a, b) => a.startDate.compareTo(b.startDate));
      return jobs;
    });
  }

  static Stream<List<JobRecord>> streamJobsForLandowner(String landownerId) {
    return _jobsCollection
        .where('landownerId', isEqualTo: landownerId)
        .snapshots()
        .map((snapshot) {
          final jobs = snapshot.docs
              .map(JobRecord.fromSnapshot)
              .toList(growable: true);

          jobs.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

          return jobs;
        });
  }

  static Future<void> deletePostedJobIfNoApplicants({
    required String landownerId,
    required String jobId,
  }) async {
    final ownerId = landownerId.trim();
    final targetJobId = jobId.trim();

    if (ownerId.isEmpty || targetJobId.isEmpty) {
      throw StateError('Missing required job details for deletion.');
    }

    final jobRef = _jobsCollection.doc(targetJobId);
    final jobSnapshot = await jobRef.get();
    final jobData = jobSnapshot.data();

    if (jobData == null) {
      throw StateError('This job no longer exists.');
    }

    final jobOwnerId = (jobData['landownerId'] as String?)?.trim() ?? '';
    if (jobOwnerId != ownerId) {
      throw StateError('Only the job owner can delete this job.');
    }

    final applicationSnapshot = await _applicationsCollection
        .where('jobId', isEqualTo: targetJobId)
        .limit(1)
        .get();
    if (applicationSnapshot.docs.isNotEmpty) {
      throw StateError('Cannot delete this job because applications already exist.');
    }

    final groupApplicationSnapshot = await _groupApplicationsCollection
        .where('jobId', isEqualTo: targetJobId)
        .limit(1)
        .get();
    if (groupApplicationSnapshot.docs.isNotEmpty) {
      throw StateError('Cannot delete this job because group applications already exist.');
    }

    await jobRef.delete();
  }

  static Stream<List<WorkerApplicationRecord>> streamApplicationsForWorker(
    String workerId,
  ) {
    return _applicationsCollection
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
          const visibleStatuses = <String>{
            'approved',
            'accepted',
            'in_progress',
            'completed',
            'expired',
          };

          final applications = snapshot.docs
              .map(WorkerApplicationRecord.fromSnapshot)
              .where((record) => visibleStatuses.contains(record.status))
              .toList(growable: true);

          applications.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

          return applications;
        });
  }

  static Stream<Set<String>> streamAppliedJobIdsForWorker(String workerId) {
    return _applicationsCollection
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['jobId'] as String?) ?? '')
              .where((jobId) => jobId.isNotEmpty)
              .toSet(),
        );
  }

  static Stream<Map<String, String>> streamGroupAppliedJobLabelsForWorker(
    String workerId,
  ) {
    return _groupApplicationsCollection
        .where('memberIds', arrayContains: workerId)
        .snapshots()
        .map(
          (snapshot) {
            final labels = <String, String>{};
            const activeStatuses = <String>{
              'submitted',
              'approved',
              'accepted',
              'in_progress',
            };
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final status = (data['status'] as String?) ?? '';
              if (!activeStatuses.contains(status)) {
                continue;
              }
              final jobId = (data['jobId'] as String?) ?? '';
              final groupName =
                  ((data['groupName'] as String?) ?? 'Group').trim();

              if (jobId.isNotEmpty) {
                labels[jobId] = groupName.isEmpty ? 'Group' : groupName;
              }
            }
            return labels;
          },
        );
  }

  static Stream<List<WorkerApplicationRecord>> streamApplicationsForJob(
    String jobId,
  ) {
    return _applicationsCollection
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snapshot) {
          final applications = snapshot.docs
              .map(WorkerApplicationRecord.fromSnapshot)
              .toList(growable: true);

          applications.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

          return applications;
        });
  }

  static Future<void> submitApplication({
    required JobRecord job,
    required String workerId,
    required String workerName,
    required String workerPhone,
  }) async {
    final hasConflict = await _hasScheduleConflict(
      workerId: workerId,
      date: job.startDate,
    );

    if (hasConflict) {
      throw StateError(
        'You are already scheduled on this date. Choose a different job date.',
      );
    }

    final duplicateQuery = await _applicationsCollection
        .where('jobId', isEqualTo: job.id)
        .where('workerId', isEqualTo: workerId)
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty) {
      throw StateError('You have already applied for this job.');
    }

    await _firestore.runTransaction((transaction) async {
      final jobRef = _jobsCollection.doc(job.id);
      final freshJobSnapshot = await transaction.get(jobRef);
      final freshJobData = freshJobSnapshot.data();

      if (freshJobData == null || freshJobData['status'] != 'open') {
        throw StateError('This job is no longer accepting applications.');
      }

      final applicationRef = _applicationsCollection.doc();
      final now = FieldValue.serverTimestamp();
      transaction.set(applicationRef, {
        'jobId': job.id,
        'jobTitle': job.title,
        'jobType': job.jobType,
        'location': job.location,
        'paymentRate': job.paymentRate,
        'startDate': Timestamp.fromDate(job.startDate),
        'estimatedDays': job.estimatedDays,
        'landownerId': job.landownerId,
        'landownerName': job.landownerName,
        'workerId': workerId,
        'workerName': workerName,
        'workerPhone': workerPhone,
        'status': 'submitted',
        'createdAt': now,
        'updatedAt': now,
      });

      final currentApplicantCount =
          ((freshJobData['applicantCount'] as num?) ?? 0).toInt();
      transaction.update(jobRef, {
        'applicantCount': currentApplicantCount + 1,
        'updatedAt': now,
      });
    });
  }

  static Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    final updatePayload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'approved') {
      final decisionDeadline = _decisionDeadlineFromNow();
      updatePayload['approvalDate'] = FieldValue.serverTimestamp();
      updatePayload['decisionDeadline'] = Timestamp.fromDate(decisionDeadline);
    } else {
      updatePayload['decisionDeadline'] = null;
    }

    await _applicationsCollection.doc(applicationId).update(updatePayload);
  }

  static Future<void> expirePendingApprovalsForWorker(String workerId) async {
    final snapshot = await _applicationsCollection
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'approved')
        .get();

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    var changed = false;

    for (final doc in snapshot.docs) {
      final deadline = (doc.data()['decisionDeadline'] as Timestamp?)?.toDate();
      if (_isExpiredDecision(deadline)) {
        changed = true;
        batch.update(doc.reference, {'status': 'expired', 'updatedAt': now});
      }
    }

    if (changed) {
      await batch.commit();
    }
  }

  static Future<void> expirePendingApprovalsForLandowner(
    String landownerId,
  ) async {
    final snapshot = await _applicationsCollection
        .where('landownerId', isEqualTo: landownerId)
        .where('status', isEqualTo: 'approved')
        .get();

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    var changed = false;

    for (final doc in snapshot.docs) {
      final deadline = (doc.data()['decisionDeadline'] as Timestamp?)?.toDate();
      if (_isExpiredDecision(deadline)) {
        changed = true;
        batch.update(doc.reference, {'status': 'expired', 'updatedAt': now});
      }
    }

    if (changed) {
      await batch.commit();
    }
  }

  static Future<void> acceptApplicationDecision({
    required String workerId,
    required String applicationId,
  }) async {
    final selectedRef = _applicationsCollection.doc(applicationId);
    final selectedSnapshot = await selectedRef.get();
    final selectedData = selectedSnapshot.data();

    if (selectedData == null || selectedData['workerId'] != workerId) {
      throw StateError('Application not found for this worker.');
    }

    if (selectedData['status'] != 'approved') {
      throw StateError('Only approved applications can be accepted.');
    }

    final decisionDeadline = (selectedData['decisionDeadline'] as Timestamp?)
        ?.toDate();
    if (_isExpiredDecision(decisionDeadline)) {
      await selectedRef.update({
        'status': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      throw StateError(
        'This offer has expired. Ask the landowner to approve again.',
      );
    }

    final selectedStartDate =
        (selectedData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final selectedEstimatedDays =
        ((selectedData['estimatedDays'] as num?) ?? 1).toInt();
    final hasConflict = await _hasScheduleRangeConflict(
      workerId: workerId,
      startDate: selectedStartDate,
      estimatedDays: selectedEstimatedDays,
    );
    if (hasConflict) {
      throw StateError(
        'You already have an accepted or in-progress job that overlaps with this time window.',
      );
    }

    final scheduleDocRef = _schedulesCollection.doc();
    final scheduleDateKey = _scheduleDateKey(selectedStartDate);

    final approvedOffersQuery = await _applicationsCollection
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'approved')
        .get();

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    final selectedEndDate =
        _inclusiveEndDate(selectedStartDate, selectedEstimatedDays);

    for (final doc in approvedOffersQuery.docs) {
      if (doc.id == applicationId) {
        batch.update(doc.reference, {
          'status': 'accepted',
          'updatedAt': now,
        });
        continue;
      }

      final offerData = doc.data();
      final offerStartDate =
          (offerData['startDate'] as Timestamp?)?.toDate() ?? selectedStartDate;
      final offerEstimatedDays = ((offerData['estimatedDays'] as num?) ?? 1).toInt();
      final offerEndDate = _inclusiveEndDate(offerStartDate, offerEstimatedDays);

      final overlaps = _rangesOverlap(
        firstStart: selectedStartDate,
        firstEnd: selectedEndDate,
        secondStart: offerStartDate,
        secondEnd: offerEndDate,
      );

      if (overlaps) {
        batch.update(doc.reference, {
          'status': 'declined_by_worker',
          'updatedAt': now,
        });
      }
    }

    batch.set(scheduleDocRef, {
      'workerId': workerId,
      'applicationId': applicationId,
      'jobId': selectedData['jobId'],
      'jobTitle': selectedData['jobTitle'],
      'landownerId': selectedData['landownerId'],
      'landownerName': selectedData['landownerName'],
      'startDate': selectedData['startDate'],
      'estimatedDays': selectedEstimatedDays,
      'scheduleDateKey': scheduleDateKey,
      'status': 'accepted',
      'createdAt': now,
      'updatedAt': now,
    });

    await batch.commit();
  }

  static Future<void> declineApplicationDecision({
    required String workerId,
    required String applicationId,
  }) async {
    final appRef = _applicationsCollection.doc(applicationId);
    final snapshot = await appRef.get();
    final data = snapshot.data();

    if (data == null || data['workerId'] != workerId) {
      throw StateError('Application not found for this worker.');
    }

    if (data['status'] != 'approved') {
      throw StateError('Only approved applications can be declined.');
    }

    await appRef.update({
      'status': 'declined_by_worker',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> submitDailyProgress({
    required String workerId,
    required String applicationId,
    required int quillCount,
    required String notes,
  }) async {
    if (quillCount <= 0) {
      throw StateError('Quill count must be greater than zero.');
    }

    final applicationRef = _applicationsCollection.doc(applicationId);
    final applicationSnapshot = await applicationRef.get();
    final applicationData = applicationSnapshot.data();

    if (applicationData == null || applicationData['workerId'] != workerId) {
      throw StateError('Application not found for this worker.');
    }

    final status = applicationData['status'] as String?;
    if (!(status == 'accepted' || status == 'in_progress')) {
      throw StateError(
        'Progress can only be added to accepted or in-progress jobs.',
      );
    }

    final jobId = (applicationData['jobId'] as String?) ?? '';
    if (jobId.isEmpty) {
      throw StateError('Job details are missing for this application.');
    }

    await _firestore.runTransaction((transaction) async {
      final now = FieldValue.serverTimestamp();
      final jobRef = _jobsCollection.doc(jobId);
      final jobSnapshot = await transaction.get(jobRef);
      final jobData = jobSnapshot.data();

      if (jobData == null) {
        throw StateError('This job no longer exists.');
      }

      final progressRef = _taskProgressCollection.doc();
      transaction.set(progressRef, {
        'jobId': jobId,
        'applicationId': applicationId,
        'groupApplicationId': '',
        'workerId': workerId,
        'workerName': applicationData['workerName'] ?? 'Worker',
        'quillCount': quillCount,
        'notes': notes,
        'progressDate': Timestamp.fromDate(DateTime.now()),
        'createdAt': now,
      });

      final currentTotal = ((jobData['totalQuillCount'] as num?) ?? 0).toInt();
      final jobStatus = (jobData['status'] as String?) ?? 'open';
      final nextJobStatus = jobStatus == 'closed' ? 'closed' : 'in_progress';

      transaction.update(jobRef, {
        'totalQuillCount': currentTotal + quillCount,
        'status': nextJobStatus,
        'updatedAt': now,
      });

      if (status == 'accepted') {
        transaction.update(applicationRef, {
          'status': 'in_progress',
          'updatedAt': now,
        });
      }
    });

    if (status == 'accepted') {
      final scheduleSnapshot = await _schedulesCollection
          .where('applicationId', isEqualTo: applicationId)
          .get();

      if (scheduleSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        final now = FieldValue.serverTimestamp();
        for (final doc in scheduleSnapshot.docs) {
          batch.update(doc.reference, {
            'status': 'in_progress',
            'updatedAt': now,
          });
        }
        await batch.commit();
      }
    }
  }

  static Future<void> submitGroupDailyProgress({
    required String workerId,
    required String groupApplicationId,
    required int quillCount,
    required String notes,
  }) async {
    if (quillCount <= 0) {
      throw StateError('Quill count must be greater than zero.');
    }

    final groupAppRef = _groupApplicationsCollection.doc(groupApplicationId);
    final groupAppSnapshot = await groupAppRef.get();
    final groupAppData = groupAppSnapshot.data();

    if (groupAppData == null) {
      throw StateError('Group application not found.');
    }

    final memberIds = ((groupAppData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
        .map((id) => id.toString())
        .toList(growable: false);
    if (!memberIds.contains(workerId)) {
      throw StateError('Only group members can submit group progress.');
    }

    final status = groupAppData['status'] as String?;
    if (!(status == 'accepted' || status == 'in_progress')) {
      throw StateError(
        'Progress can only be added to accepted or in-progress group jobs.',
      );
    }

    final jobId = (groupAppData['jobId'] as String?) ?? '';
    if (jobId.isEmpty) {
      throw StateError('Job details are missing for this group application.');
    }

    final workerSnapshot = await _firestore.collection('users').doc(workerId).get();
    final workerName = ((workerSnapshot.data()?['name'] as String?) ?? 'Worker').trim();

    await _firestore.runTransaction((transaction) async {
      final now = FieldValue.serverTimestamp();
      final jobRef = _jobsCollection.doc(jobId);
      final jobSnapshot = await transaction.get(jobRef);
      final jobData = jobSnapshot.data();

      if (jobData == null) {
        throw StateError('This job no longer exists.');
      }

      final progressRef = _taskProgressCollection.doc();
      transaction.set(progressRef, {
        'jobId': jobId,
        'applicationId': '',
        'groupApplicationId': groupApplicationId,
        'workerId': workerId,
        'workerName': workerName.isEmpty ? 'Worker' : workerName,
        'quillCount': quillCount,
        'notes': notes,
        'progressDate': Timestamp.fromDate(DateTime.now()),
        'createdAt': now,
      });

      final currentTotal = ((jobData['totalQuillCount'] as num?) ?? 0).toInt();
      final jobStatus = (jobData['status'] as String?) ?? 'open';
      final nextJobStatus = jobStatus == 'closed' ? 'closed' : 'in_progress';

      transaction.update(jobRef, {
        'totalQuillCount': currentTotal + quillCount,
        'status': nextJobStatus,
        'updatedAt': now,
      });

      if (status == 'accepted') {
        transaction.update(groupAppRef, {
          'status': 'in_progress',
          'updatedAt': now,
        });
      }
    });

    if (status == 'accepted') {
      final scheduleSnapshot = await _schedulesCollection
          .where('groupApplicationId', isEqualTo: groupApplicationId)
          .get();

      if (scheduleSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        final now = FieldValue.serverTimestamp();
        for (final doc in scheduleSnapshot.docs) {
          batch.update(doc.reference, {
            'status': 'in_progress',
            'updatedAt': now,
          });
        }
        await batch.commit();
      }
    }
  }

  static Future<void> markApplicationCompleted({
    required String workerId,
    required String applicationId,
  }) async {
    final appRef = _applicationsCollection.doc(applicationId);
    final appSnapshot = await appRef.get();
    final appData = appSnapshot.data();

    if (appData == null || appData['workerId'] != workerId) {
      throw StateError('Application not found for this worker.');
    }

    final currentStatus = appData['status'] as String?;
    if (!(currentStatus == 'accepted' || currentStatus == 'in_progress')) {
      throw StateError(
        'Only accepted or in-progress jobs can be marked as completed.',
      );
    }

    final now = FieldValue.serverTimestamp();

    final scheduleQuery = await _schedulesCollection
        .where('applicationId', isEqualTo: applicationId)
        .limit(1)
        .get();

    final batch = _firestore.batch();
    batch.update(appRef, {'status': 'completed', 'updatedAt': now});

    if (scheduleQuery.docs.isNotEmpty) {
      batch.update(scheduleQuery.docs.first.reference, {
        'status': 'completed',
        'updatedAt': now,
      });
    }

    await batch.commit();

    final jobId = (appData['jobId'] as String?) ?? '';
    if (jobId.isNotEmpty) {
      await _closeJobIfNoActiveApplications(jobId);
    }
  }

  static Future<void> markGroupApplicationCompleted({
    required String workerId,
    required String groupApplicationId,
  }) async {
    final appRef = _groupApplicationsCollection.doc(groupApplicationId);
    final appSnapshot = await appRef.get();
    final appData = appSnapshot.data();

    if (appData == null) {
      throw StateError('Group application not found.');
    }

    final coordinatorId = (appData['coordinatorId'] as String?)?.trim() ?? '';
    if (coordinatorId != workerId.trim()) {
      throw StateError('Only the group coordinator can mark this job as completed.');
    }

    final currentStatus = (appData['status'] as String?) ?? '';
    if (!(currentStatus == 'accepted' || currentStatus == 'in_progress')) {
      throw StateError(
        'Only accepted or in-progress group jobs can be marked as completed.',
      );
    }

    final now = FieldValue.serverTimestamp();
    final scheduleSnapshot = await _schedulesCollection
        .where('groupApplicationId', isEqualTo: groupApplicationId)
        .get();

    final batch = _firestore.batch();
    batch.update(appRef, {
      'status': 'completed',
      'updatedAt': now,
    });

    for (final doc in scheduleSnapshot.docs) {
      batch.update(doc.reference, {
        'status': 'completed',
        'updatedAt': now,
      });
    }

    await batch.commit();

    final jobId = (appData['jobId'] as String?) ?? '';
    if (jobId.isNotEmpty) {
      await _closeJobIfNoActiveApplications(jobId);
    }
  }

  static Future<void> _closeJobIfNoActiveApplications(String jobId) async {
    final activeOrPendingIndividualSnapshot = await _applicationsCollection
        .where('jobId', isEqualTo: jobId)
        .where('status', whereIn: ['approved', 'accepted', 'in_progress'])
        .limit(1)
        .get();

    if (activeOrPendingIndividualSnapshot.docs.isNotEmpty) {
      return;
    }

    final activeOrPendingGroupSnapshot = await _groupApplicationsCollection
        .where('jobId', isEqualTo: jobId)
        .where('status', whereIn: ['approved', 'accepted', 'in_progress'])
        .limit(1)
        .get();

    if (activeOrPendingGroupSnapshot.docs.isNotEmpty) {
      return;
    }

    final hasCompletedIndividualSnapshot = await _applicationsCollection
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();

    final hasCompletedGroupSnapshot = await _groupApplicationsCollection
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();

    final hasAnyCompleted =
        hasCompletedIndividualSnapshot.docs.isNotEmpty ||
        hasCompletedGroupSnapshot.docs.isNotEmpty;
    if (!hasAnyCompleted) {
      return;
    }

    await _jobsCollection.doc(jobId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> submitRating({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required String jobId,
    required double rating,
    required String feedback,
  }) async {
    final fromId = fromUserId.trim();
    final toId = toUserId.trim();
    final targetJobId = jobId.trim();

    if (fromId.isEmpty) {
      throw StateError('Your user account is missing. Please sign in again.');
    }

    if (toId.isEmpty) {
      throw StateError('Landowner details are missing for this job.');
    }

    if (targetJobId.isEmpty) {
      throw StateError('Job details are missing for this rating.');
    }

    if (fromId == toId) {
      throw StateError('You cannot rate yourself.');
    }

    if (rating < 1 || rating > 5) {
      throw StateError('Rating must be between 1 and 5.');
    }

    final users = _firestore.collection('users');
    final fromUserSnapshot = await users.doc(fromId).get();
    final toUserSnapshot = await users.doc(toId).get();
    final fromRole = (fromUserSnapshot.data()?['role'] as String?)?.trim() ?? '';
    final toRole = (toUserSnapshot.data()?['role'] as String?)?.trim() ?? '';

    final validFromRole = fromRole == 'worker' || fromRole == 'landowner';
    final validToRole = toRole == 'worker' || toRole == 'landowner';
    if (!validFromRole || !validToRole) {
      throw StateError('Only workers and landowners can participate in ratings.');
    }

    if (fromRole == toRole) {
      throw StateError('Workers cannot rate workers and landowners cannot rate landowners.');
    }

    if (fromRole == 'worker') {
      // A worker can rate at most once per job.
      final existingWorkerRatingSnapshot = await _ratingsCollection
          .where('fromUserId', isEqualTo: fromId)
          .where('fromUserRole', isEqualTo: 'worker')
          .where('jobId', isEqualTo: targetJobId)
          .limit(1)
          .get();

      if (existingWorkerRatingSnapshot.docs.isNotEmpty) {
        throw StateError('You have already submitted your rating for this job.');
      }
    } else {
      // Landowners can rate multiple workers on the same job,
      // but only once per target worker.
      final existingRatingSnapshot = await _ratingsCollection
          .where('fromUserId', isEqualTo: fromId)
          .where('toUserId', isEqualTo: toId)
          .where('jobId', isEqualTo: targetJobId)
          .limit(1)
          .get();

      if (existingRatingSnapshot.docs.isNotEmpty) {
        throw StateError('You have already submitted a rating for this job.');
      }
    }

    final now = FieldValue.serverTimestamp();

    // Always persist the rating first.
    await _ratingsCollection.add({
      'fromUserId': fromId,
      'fromUserName': fromUserName,
      'fromUserRole': fromRole,
      'toUserId': toId,
      'toUserName': toUserName,
      'toUserRole': toRole,
      'jobId': targetJobId,
      'rating': rating,
      'feedback': feedback,
      'createdAt': now,
    });

    // Best-effort aggregate update for profile summary fields.
    try {
      final toUserRef = _firestore.collection('users').doc(toId);
      final toUserSnapshot = await toUserRef.get();
      final toUserData = toUserSnapshot.data() ?? <String, dynamic>{};

      final currentRatings = ((toUserData['totalRatings'] as num?) ?? 0)
          .toDouble();
      final currentRatingSum = ((toUserData['totalRatingSum'] as num?) ?? 0)
          .toDouble();
      final newTotal = currentRatings + 1;
      final newSum = currentRatingSum + rating;
      final newAverage = newSum / newTotal;

      await toUserRef.set({
        'totalRatings': newTotal,
        'totalRatingSum': newSum,
        'averageRating': newAverage,
        'updatedAt': now,
      }, SetOptions(merge: true));
    } catch (_) {
      // Keep rating submission successful even if summary update is blocked.
    }
  }

  static Future<bool> hasRatingForJob({
    required String fromUserId,
    required String toUserId,
    required String jobId,
  }) async {
    final fromId = fromUserId.trim();
    final toId = toUserId.trim();
    final targetJobId = jobId.trim();

    if (fromId.isEmpty || toId.isEmpty || targetJobId.isEmpty) {
      return false;
    }

    final existingRatingSnapshot = await _ratingsCollection
        .where('fromUserId', isEqualTo: fromId)
        .where('toUserId', isEqualTo: toId)
        .where('jobId', isEqualTo: targetJobId)
        .limit(1)
        .get();

    return existingRatingSnapshot.docs.isNotEmpty;
  }

  static Future<Map<String, int>> submitRatingToGroupMembers({
    required String landownerId,
    required String landownerName,
    required String groupApplicationId,
    required double rating,
    required String feedback,
  }) async {
    final fromId = landownerId.trim();
    final fromName = landownerName.trim().isEmpty ? 'Landowner' : landownerName.trim();
    final appId = groupApplicationId.trim();

    if (fromId.isEmpty) {
      throw StateError('Your user account is missing. Please sign in again.');
    }
    if (appId.isEmpty) {
      throw StateError('Group application details are missing.');
    }

    final appSnapshot = await _groupApplicationsCollection.doc(appId).get();
    final appData = appSnapshot.data();
    if (appData == null) {
      throw StateError('Group application not found.');
    }

    final appLandownerId = (appData['landownerId'] as String?)?.trim() ?? '';
    if (appLandownerId != fromId) {
      throw StateError('You can only rate workers for your own group applications.');
    }

    final jobId = (appData['jobId'] as String?)?.trim() ?? '';
    if (jobId.isEmpty) {
      throw StateError('Job details are missing for this group application.');
    }

    final memberIds = ((appData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
        .map((id) => id.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (memberIds.isEmpty) {
      throw StateError('No members found in this group application.');
    }

    var submitted = 0;
    var skipped = 0;
    var failed = 0;

    for (final memberId in memberIds) {
      if (memberId == fromId) {
        skipped += 1;
        continue;
      }

      try {
        final alreadyRated = await hasRatingForJob(
          fromUserId: fromId,
          toUserId: memberId,
          jobId: jobId,
        );

        if (alreadyRated) {
          skipped += 1;
          continue;
        }

        final memberSnapshot = await _firestore.collection('users').doc(memberId).get();
        final memberName =
            (memberSnapshot.data()?['name'] as String?)?.trim().isNotEmpty == true
                ? (memberSnapshot.data()?['name'] as String)
                : 'Worker';

        await submitRating(
          fromUserId: fromId,
          fromUserName: fromName,
          toUserId: memberId,
          toUserName: memberName,
          jobId: jobId,
          rating: rating,
          feedback: feedback,
        );
        submitted += 1;
      } catch (_) {
        failed += 1;
      }
    }

    if (submitted == 0 && failed > 0) {
      throw StateError('Could not submit ratings for group members. Please try again.');
    }

    return {
      'submitted': submitted,
      'skipped': skipped,
      'failed': failed,
    };
  }

  static Stream<List<RatingRecord>> streamRatingsForUser(
    String userId, {
    int limit = 50,
  }) {
    final trimmedId = userId.trim();
    if (trimmedId.isEmpty) {
      return const Stream<List<RatingRecord>>.empty();
    }

    return _ratingsCollection
        .where('toUserId', isEqualTo: trimmedId)
        .snapshots()
        .map(
          (snapshot) {
            final records = snapshot.docs
                .map(RatingRecord.fromSnapshot)
                .where((record) => record.fromUserId.isNotEmpty)
                .toList(growable: false);
            // Sort by createdAt descending in code (avoids needing composite Firestore index)
            records.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            // Apply limit in code
            return records.take(limit).toList();
          },
        );
  }

  static Future<Map<String, dynamic>> getWorkerMetrics(String workerId) async {
    final applicationsSnapshot = await _applicationsCollection
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'completed')
        .get();

    final completedCount = applicationsSnapshot.docs.length;

    final userSnapshot = await _firestore
        .collection('users')
        .doc(workerId)
        .get();
    final userData = userSnapshot.data() ?? <String, dynamic>{};

    final totalRatings = ((userData['totalRatings'] as num?) ?? 0).toDouble();
    final totalRatingSum = ((userData['totalRatingSum'] as num?) ?? 0)
        .toDouble();
    final averageRating = totalRatings > 0
        ? totalRatingSum / totalRatings
        : ((userData['averageRating'] as num?) ?? 0).toDouble();

    return {
      'completedJobsCount': completedCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings.toInt(),
    };
  }

  static Future<Map<String, dynamic>> getLandownerMetrics(
    String landownerId,
  ) async {
    final jobsSnapshot = await _jobsCollection
        .where('landownerId', isEqualTo: landownerId)
        .where('status', isEqualTo: 'closed')
        .get();

    final completedJobsCount = jobsSnapshot.docs.length;

    final userSnapshot = await _firestore
        .collection('users')
        .doc(landownerId)
        .get();
    final userData = userSnapshot.data() ?? <String, dynamic>{};

    final totalRatings = ((userData['totalRatings'] as num?) ?? 0).toDouble();
    final totalRatingSum = ((userData['totalRatingSum'] as num?) ?? 0)
        .toDouble();
    final averageRating = totalRatings > 0
        ? totalRatingSum / totalRatings
        : ((userData['averageRating'] as num?) ?? 0).toDouble();

    return {
      'completedJobsCount': completedJobsCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings.toInt(),
    };
  }

  static Stream<List<WorkerGroupRecord>> streamGroupsForWorker(
    String workerId,
  ) {
    return _workerGroupsCollection
        .where('memberIds', arrayContains: workerId)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map(WorkerGroupRecord.fromSnapshot)
              .where((group) => group.status == 'active')
              .toList(growable: true);

          groups.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

          return groups;
        });
  }

  static Future<void> createWorkerGroup({
    required String coordinatorId,
    required String coordinatorName,
    required String groupName,
  }) async {
    final trimmedName = groupName.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Group name is required.');
    }

    final groupNameKey = _normalizeGroupName(trimmedName);
    final existingGroupByKey = await _workerGroupsCollection
        .where('groupNameKey', isEqualTo: groupNameKey)
      .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (existingGroupByKey.docs.isNotEmpty) {
      throw StateError('This group name is already taken.');
    }

    final existingGroupByName = await _workerGroupsCollection
        .where('groupName', isEqualTo: trimmedName)
      .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (existingGroupByName.docs.isNotEmpty) {
      throw StateError('This group name is already taken.');
    }

    final now = FieldValue.serverTimestamp();
    final joinedAt = Timestamp.now();
    await _workerGroupsCollection.add({
      'groupName': trimmedName,
      'groupNameKey': groupNameKey,
      'coordinatorId': coordinatorId,
      'coordinatorName': coordinatorName,
      'memberIds': [coordinatorId],
      'members': [
        {
          'workerId': coordinatorId,
          'workerName': coordinatorName,
          'workerPhone': '',
          'role': 'coordinator',
          'joinedAt': joinedAt,
        },
      ],
      'status': 'active',
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static String _normalizeGroupName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static Future<void> addMemberToGroup({
    required String groupId,
    required String coordinatorId,
    required String memberWorkerId,
  }) async {
    final memberId = memberWorkerId.trim();
    if (memberId.isEmpty) {
      throw StateError('Worker ID is required.');
    }

    if (memberId == coordinatorId) {
      throw StateError('You are already in the group as coordinator.');
    }

    final userRef = _firestore.collection('users').doc(memberId);
    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    if (userData == null) {
      throw StateError('Worker not found for this ID.');
    }

    final userRole = (userData['role'] as String?)?.trim() ?? '';
    if (userRole != 'worker') {
      throw StateError('Only worker accounts can be added to a worker group.');
    }

    final memberName = (userData['name'] as String?)?.trim();
    final memberPhone = (userData['phone'] as String?)?.trim() ?? '';

    final groupRef = _workerGroupsCollection.doc(groupId);
    final groupSnapshot = await groupRef.get();
    final groupData = groupSnapshot.data();

    if (groupData == null) {
      throw StateError('Group not found.');
    }

    if (groupData['coordinatorId'] != coordinatorId) {
      throw StateError('Only the group coordinator can add members.');
    }

    final memberIds =
        ((groupData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
            .map((id) => id.toString())
            .toList(growable: false);

    if (memberIds.contains(memberId)) {
      throw StateError('This worker is already in the group.');
    }

    await _firestore.runTransaction((transaction) async {
      final now = FieldValue.serverTimestamp();
      final joinedAt = Timestamp.now();
      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([memberId]),
        'members': FieldValue.arrayUnion([
          {
            'workerId': memberId,
            'workerName': memberName == null || memberName.isEmpty
                ? 'Worker'
                : memberName,
            'workerPhone': memberPhone,
            'role': 'member',
            'joinedAt': joinedAt,
          },
        ]),
        'updatedAt': now,
      });
    });
  }

  static Future<void> addMemberToGroupByPhone({
    required String groupId,
    required String coordinatorId,
    required String phoneNumber,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isEmpty) {
      throw StateError('Phone number is required.');
    }

    final userDoc = await _findUserByPhone(trimmedPhone);
    if (userDoc == null) {
      throw StateError('No worker account found for this phone number.');
    }

    if (userDoc.id == coordinatorId) {
      throw StateError('You are already in the group as coordinator.');
    }

    await addMemberToGroup(
      groupId: groupId,
      coordinatorId: coordinatorId,
      memberWorkerId: userDoc.id,
    );
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserByPhone(
    String phoneNumber,
  ) async {
    final users = _firestore.collection('users');
    final directMatch = await users
        .where('phone', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (directMatch.docs.isNotEmpty) {
      return directMatch.docs.first;
    }

    final normalized = _normalizePhoneForLookup(phoneNumber);
    if (normalized == phoneNumber) {
      return null;
    }

    final normalizedMatch = await users
        .where('phone', isEqualTo: normalized)
        .limit(1)
        .get();
    if (normalizedMatch.docs.isNotEmpty) {
      return normalizedMatch.docs.first;
    }

    return null;
  }

  static String _normalizePhoneForLookup(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return value.trim();
    }
    if (digits.startsWith('94')) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return '+94${digits.substring(1)}';
    }
    return '+94$digits';
  }

  static Future<void> deleteWorkerGroup({
    required String groupId,
    required String coordinatorId,
  }) async {
    final groupRef = _workerGroupsCollection.doc(groupId);
    final groupSnapshot = await groupRef.get();
    final groupData = groupSnapshot.data();

    if (groupData == null) {
      throw StateError('Group not found.');
    }

    if (groupData['coordinatorId'] != coordinatorId) {
      throw StateError('Only the group coordinator can delete this group.');
    }

    final hasActiveCommitment = await _hasBlockingGroupCommitment(
      groupId: groupId,
    );
    if (hasActiveCommitment) {
      throw StateError(
        'Cannot delete this group while it has approved or accepted group applications.',
      );
    }

    await groupRef.update({
      'status': 'deleted',
      'memberIds': <String>[],
      'members': <Map<String, dynamic>>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeMemberFromGroup({
    required String groupId,
    required String coordinatorId,
    required String memberWorkerId,
  }) async {
    final memberId = memberWorkerId.trim();
    if (memberId.isEmpty) {
      throw StateError('Worker ID is required.');
    }

    final groupRef = _workerGroupsCollection.doc(groupId);
    await _firestore.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(groupRef);
      final groupData = groupSnapshot.data();

      if (groupData == null) {
        throw StateError('Group not found.');
      }

      if (groupData['coordinatorId'] != coordinatorId) {
        throw StateError('Only the coordinator can remove members.');
      }

      if (memberId == coordinatorId) {
        throw StateError(
          'Coordinator cannot remove self. Use Exit Group instead.',
        );
      }

      final hasActiveCommitmentForMember = await _hasBlockingGroupCommitment(
        groupId: groupId,
        memberWorkerId: memberId,
      );
      if (hasActiveCommitmentForMember) {
        throw StateError(
          'Cannot remove this member while they are part of an approved or accepted group application.',
        );
      }

      final memberIds =
          ((groupData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
              .map((id) => id.toString())
              .toList(growable: true);

      if (!memberIds.contains(memberId)) {
        throw StateError('Member is not part of this group.');
      }

      memberIds.removeWhere((id) => id == memberId);

      final rawMembers = (groupData['members'] as List<dynamic>?) ?? const [];
      final updatedMembers = rawMembers
          .whereType<Map>()
          .map(
            (member) =>
                member.map((key, value) => MapEntry(key.toString(), value)),
          )
          .where((member) => (member['workerId'] as String?) != memberId)
          .toList(growable: false);

      if (memberIds.isEmpty) {
        transaction.delete(groupRef);
        return;
      }

      transaction.update(groupRef, {
        'memberIds': memberIds,
        'members': updatedMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> leaveGroup({
    required String groupId,
    required String workerId,
  }) async {
    final memberId = workerId.trim();
    if (memberId.isEmpty) {
      throw StateError('Worker ID is required.');
    }

    final groupRef = _workerGroupsCollection.doc(groupId);
    await _firestore.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(groupRef);
      final groupData = groupSnapshot.data();

      if (groupData == null) {
        throw StateError('Group not found.');
      }

      final coordinatorId = (groupData['coordinatorId'] as String?) ?? '';
      final memberIds =
          ((groupData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
              .map((id) => id.toString())
              .toList(growable: true);

      if (!memberIds.contains(memberId)) {
        throw StateError('You are not part of this group.');
      }

      final hasActiveCommitmentForMember = await _hasBlockingGroupCommitment(
        groupId: groupId,
        memberWorkerId: memberId,
      );
      if (hasActiveCommitmentForMember) {
        throw StateError(
          'You cannot exit this group while you are part of an approved or accepted group application.',
        );
      }

      final rawMembers = (groupData['members'] as List<dynamic>?) ?? const [];
      final members = rawMembers
          .whereType<Map>()
          .map(
            (member) =>
                member.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: true);

      memberIds.removeWhere((id) => id == memberId);
      members.removeWhere(
        (member) => (member['workerId'] as String?) == memberId,
      );

      if (memberIds.isEmpty) {
        transaction.delete(groupRef);
        return;
      }

      if (coordinatorId == memberId) {
        final newCoordinatorId = memberIds.first;
        final promotedIndex = members.indexWhere(
          (member) => (member['workerId'] as String?) == newCoordinatorId,
        );

        String newCoordinatorName = 'Coordinator';
        if (promotedIndex >= 0) {
          members[promotedIndex] = {
            ...members[promotedIndex],
            'role': 'coordinator',
          };
          newCoordinatorName =
              (members[promotedIndex]['workerName'] as String?)?.trim() ??
              'Coordinator';
        }

        transaction.update(groupRef, {
          'coordinatorId': newCoordinatorId,
          'coordinatorName': newCoordinatorName.isEmpty
              ? 'Coordinator'
              : newCoordinatorName,
          'memberIds': memberIds,
          'members': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      transaction.update(groupRef, {
        'memberIds': memberIds,
        'members': members,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<bool> _hasBlockingGroupCommitment({
    required String groupId,
    String? memberWorkerId,
  }) async {
    final snapshot = await _groupApplicationsCollection
        .where('groupId', isEqualTo: groupId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] as String?) ?? '';
      final isBlocking = status == 'approved' || status == 'accepted';
      if (!isBlocking) {
        continue;
      }

      if (memberWorkerId == null) {
        return true;
      }

      final memberIds =
          ((data['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
              .map((id) => id.toString())
              .toList(growable: false);

      if (memberIds.contains(memberWorkerId)) {
        return true;
      }
    }

    return false;
  }

  static Stream<List<GroupJobApplicationRecord>>
  streamGroupApplicationsForCoordinator(String coordinatorId) {
    return _groupApplicationsCollection
        .where('coordinatorId', isEqualTo: coordinatorId)
        .snapshots()
        .map((snapshot) {
          final applications = snapshot.docs
              .map(GroupJobApplicationRecord.fromSnapshot)
              .toList(growable: true);
          applications.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          return applications;
        });
  }

  static Stream<List<GroupJobApplicationRecord>>
  streamGroupApplicationsForWorker(String workerId) {
    return _groupApplicationsCollection
        .where('memberIds', arrayContains: workerId)
        .snapshots()
        .map((snapshot) {
          final applications = snapshot.docs
              .map(GroupJobApplicationRecord.fromSnapshot)
              .toList(growable: true);
          applications.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          return applications;
        });
  }

  static Stream<List<GroupJobApplicationRecord>> streamGroupApplicationsForJob(
    String jobId,
  ) {
    return _groupApplicationsCollection
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snapshot) {
          final applications = snapshot.docs
              .map(GroupJobApplicationRecord.fromSnapshot)
              .toList(growable: true);
          applications.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          return applications;
        });
  }

  static Future<List<String>> fetchGroupMemberNames({
    required String groupId,
    List<String> fallbackMemberIds = const <String>[],
  }) async {
    if (groupId.isNotEmpty) {
      final groupSnapshot = await _workerGroupsCollection.doc(groupId).get();
      final groupData = groupSnapshot.data();
      if (groupData != null) {
        final members = ((groupData['members'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((member) => member['name']?.toString().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toList(growable: false);
        if (members.isNotEmpty) {
          return members;
        }
      }
    }

    if (fallbackMemberIds.isEmpty) {
      return const <String>[];
    }

    final names = <String>[];
    for (final memberId in fallbackMemberIds) {
      final userSnapshot = await _firestore.collection('users').doc(memberId).get();
      final userData = userSnapshot.data();
      final name = userData?['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        names.add(name);
      }
    }

    return names;
  }

  static Future<void> submitGroupApplication({
    required JobRecord job,
    required String groupId,
    required String coordinatorId,
  }) async {
    final groupRef = _workerGroupsCollection.doc(groupId);
    final groupSnapshot = await groupRef.get();
    final groupData = groupSnapshot.data();

    if (groupData == null) {
      throw StateError('Group not found.');
    }

    if (groupData['coordinatorId'] != coordinatorId) {
      throw StateError('Only the group coordinator can apply for a group.');
    }

    final memberIds =
        ((groupData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
            .map((id) => id.toString())
            .toList(growable: false);
    final memberNames = ((groupData['members'] as List<dynamic>?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((member) => member['name']?.toString().trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

    if (memberIds.isEmpty) {
      throw StateError('This group has no members.');
    }

    for (final memberId in memberIds) {
      final hasConflict = await _hasScheduleRangeConflict(
        workerId: memberId,
        startDate: job.startDate,
        estimatedDays: job.estimatedDays,
      );
      if (hasConflict) {
        throw StateError(
          'Group member $memberId has a schedule conflict in this time window.',
        );
      }
    }

    final duplicateQuery = await _groupApplicationsCollection
        .where('jobId', isEqualTo: job.id)
        .where('groupId', isEqualTo: groupId)
        .get();

    const activeStatuses = <String>{'submitted', 'approved', 'accepted', 'in_progress'};
    final hasActiveDuplicate = duplicateQuery.docs.any((doc) {
      final status = (doc.data()['status'] as String?) ?? '';
      return activeStatuses.contains(status);
    });

    if (hasActiveDuplicate) {
      throw StateError('This group has already applied for this job.');
    }

    final jobRef = _jobsCollection.doc(job.id);
    final freshJobSnapshot = await jobRef.get();
    final freshJobData = freshJobSnapshot.data();
    if (freshJobData == null || freshJobData['status'] != 'open') {
      throw StateError('This job is no longer accepting applications.');
    }

    final now = FieldValue.serverTimestamp();
    await _groupApplicationsCollection.add({
      'jobId': job.id,
      'jobTitle': job.title,
      'startDate': Timestamp.fromDate(job.startDate),
      'estimatedDays': job.estimatedDays,
      'groupId': groupId,
      'groupName': (groupData['groupName'] as String?) ?? 'Group',
      'coordinatorId': coordinatorId,
      'coordinatorName':
          (groupData['coordinatorName'] as String?) ?? 'Coordinator',
      'landownerId': job.landownerId,
      'landownerName': job.landownerName,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'memberCount': memberIds.length,
      'status': 'submitted',
      'createdAt': now,
      'updatedAt': now,
    });

    await jobRef.update({
      'applicantCount': FieldValue.increment(1),
      'updatedAt': now,
    });
  }

  static Future<void> updateGroupApplicationStatus({
    required String groupApplicationId,
    required String status,
  }) async {
    final updatePayload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'approved') {
      final decisionDeadline = _decisionDeadlineFromNow();
      updatePayload['approvalDate'] = FieldValue.serverTimestamp();
      updatePayload['decisionDeadline'] = Timestamp.fromDate(decisionDeadline);
    } else {
      updatePayload['decisionDeadline'] = null;
    }

    await _groupApplicationsCollection.doc(groupApplicationId).update(updatePayload);
  }

  static Future<void> acceptGroupApplicationDecision({
    required String landownerId,
    required String groupApplicationId,
  }) async {
    final appRef = _groupApplicationsCollection.doc(groupApplicationId);
    final appSnapshot = await appRef.get();
    final appData = appSnapshot.data();

    if (appData == null) {
      throw StateError('Group application not found.');
    }

    if (appData['landownerId'] != landownerId) {
      throw StateError('You can only accept applications for your own jobs.');
    }

    await _acceptGroupApplicationCore(
      groupApplicationId: groupApplicationId,
      appData: appData,
    );
  }

  static Future<void> acceptGroupApplicationByCoordinator({
    required String coordinatorId,
    required String groupApplicationId,
  }) async {
    final appRef = _groupApplicationsCollection.doc(groupApplicationId);
    final appSnapshot = await appRef.get();
    final appData = appSnapshot.data();

    if (appData == null) {
      throw StateError('Group application not found.');
    }

    if (appData['coordinatorId'] != coordinatorId) {
      throw StateError('Only the group coordinator can accept this offer.');
    }

    await _acceptGroupApplicationCore(
      groupApplicationId: groupApplicationId,
      appData: appData,
    );
  }

  static Future<void> declineGroupApplicationByCoordinator({
    required String coordinatorId,
    required String groupApplicationId,
  }) async {
    final appRef = _groupApplicationsCollection.doc(groupApplicationId);
    final appSnapshot = await appRef.get();
    final appData = appSnapshot.data();

    if (appData == null) {
      throw StateError('Group application not found.');
    }

    if (appData['coordinatorId'] != coordinatorId) {
      throw StateError('Only the group coordinator can decline this offer.');
    }

    if (appData['status'] != 'approved') {
      throw StateError('Only approved group offers can be declined.');
    }

    await appRef.update({
      'status': 'declined_by_group',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _acceptGroupApplicationCore({
    required String groupApplicationId,
    required Map<String, dynamic> appData,
  }) async {
    final appRef = _groupApplicationsCollection.doc(groupApplicationId);

    if (appData['status'] != 'approved') {
      throw StateError('Only approved group applications can be accepted.');
    }

    final decisionDeadline =
        (appData['decisionDeadline'] as Timestamp?)?.toDate();
    if (_isExpiredDecision(decisionDeadline)) {
      await appRef.update({
        'status': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      throw StateError(
        'This group offer has expired. Ask the landowner to approve again.',
      );
    }

    final jobId = (appData['jobId'] as String?) ?? '';
    if (jobId.isEmpty) {
      throw StateError('Job details missing for this group application.');
    }

    final jobSnapshot = await _jobsCollection.doc(jobId).get();
    final jobData = jobSnapshot.data();
    if (jobData == null) {
      throw StateError('Job no longer exists.');
    }

    final startDate =
        (jobData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final estimatedDays = ((jobData['estimatedDays'] as num?) ?? 1).toInt();
    final memberIds =
        ((appData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
            .map((id) => id.toString())
            .where((id) => id.isNotEmpty)
            .toList(growable: false);

    if (memberIds.isEmpty) {
      throw StateError('This group has no members to schedule.');
    }

    for (final memberId in memberIds) {
      final hasConflict = await _hasScheduleRangeConflict(
        workerId: memberId,
        startDate: startDate,
        estimatedDays: estimatedDays,
      );
      if (hasConflict) {
        throw StateError(
          'Member $memberId already has an accepted or in-progress job that overlaps this time window.',
        );
      }
    }

    final now = FieldValue.serverTimestamp();
    final scheduleDateKey = _scheduleDateKey(startDate);
    final batch = _firestore.batch();
    final selectedEndDate = _inclusiveEndDate(startDate, estimatedDays);

    final overlappingApprovedIndividualIds = <String>{};
    final overlappingApprovedGroupIds = <String>{};

    for (final memberId in memberIds) {
      final approvedIndividualOffers = await _applicationsCollection
          .where('workerId', isEqualTo: memberId)
          .where('status', isEqualTo: 'approved')
          .get();

      for (final doc in approvedIndividualOffers.docs) {
        final data = doc.data();
        final offerStartDate =
            (data['startDate'] as Timestamp?)?.toDate() ?? startDate;
        final offerEstimatedDays = ((data['estimatedDays'] as num?) ?? 1).toInt();
        final offerEndDate = _inclusiveEndDate(offerStartDate, offerEstimatedDays);

        final overlaps = _rangesOverlap(
          firstStart: startDate,
          firstEnd: selectedEndDate,
          secondStart: offerStartDate,
          secondEnd: offerEndDate,
        );

        if (overlaps) {
          overlappingApprovedIndividualIds.add(doc.id);
        }
      }

      final approvedGroupOffers = await _groupApplicationsCollection
          .where('memberIds', arrayContains: memberId)
          .where('status', isEqualTo: 'approved')
          .get();

      for (final doc in approvedGroupOffers.docs) {
        if (doc.id == groupApplicationId) {
          continue;
        }

        final data = doc.data();
        final offerStartDate =
            (data['startDate'] as Timestamp?)?.toDate() ?? startDate;
        final offerEstimatedDays = ((data['estimatedDays'] as num?) ?? 1).toInt();
        final offerEndDate = _inclusiveEndDate(offerStartDate, offerEstimatedDays);

        final overlaps = _rangesOverlap(
          firstStart: startDate,
          firstEnd: selectedEndDate,
          secondStart: offerStartDate,
          secondEnd: offerEndDate,
        );

        if (overlaps) {
          overlappingApprovedGroupIds.add(doc.id);
        }
      }
    }

    batch.update(appRef, {'status': 'accepted', 'updatedAt': now});

    for (final applicationId in overlappingApprovedIndividualIds) {
      batch.update(_applicationsCollection.doc(applicationId), {
        'status': 'declined_by_worker',
        'updatedAt': now,
      });
    }

    for (final otherGroupApplicationId in overlappingApprovedGroupIds) {
      batch.update(_groupApplicationsCollection.doc(otherGroupApplicationId), {
        'status': 'declined_by_group',
        'updatedAt': now,
      });
    }

    for (final memberId in memberIds) {
      final scheduleRef = _schedulesCollection.doc();
      batch.set(scheduleRef, {
        'workerId': memberId,
        'applicationId': null,
        'groupApplicationId': groupApplicationId,
        'groupId': appData['groupId'],
        'groupName': appData['groupName'],
        'jobId': jobId,
        'jobTitle': appData['jobTitle'],
        'landownerId': appData['landownerId'],
        'landownerName': appData['landownerName'],
        'startDate': Timestamp.fromDate(startDate),
        'estimatedDays': estimatedDays,
        'scheduleDateKey': scheduleDateKey,
        'status': 'accepted',
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }
}
