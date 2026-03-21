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
    required this.toUserId,
    required this.toUserName,
    required this.jobId,
    required this.rating,
    required this.feedback,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
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
      toUserId: (data['toUserId'] as String?) ?? '',
      toUserName: (data['toUserName'] as String?) ?? 'User',
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
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GroupJobApplicationRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawMemberIds = (data['memberIds'] as List<dynamic>?) ?? const [];

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
      memberIds: rawMemberIds
          .map((id) => id.toString())
          .toList(growable: false),
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TaskProgressRecord.fromSnapshot)
              .toList(growable: false),
        );
  }

  static Stream<List<TaskProgressRecord>> streamProgressForJob(String jobId) {
    return _taskProgressCollection
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TaskProgressRecord.fromSnapshot)
              .toList(growable: false),
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
        .map((snapshot) {
          final labels = <String, String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final jobId = (data['jobId'] as String?) ?? '';
            final groupName = ((data['groupName'] as String?) ?? 'Group')
                .trim();

            if (jobId.isNotEmpty) {
              labels[jobId] = groupName.isEmpty ? 'Group' : groupName;
            }
          }
          return labels;
        });
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
    final hasConflict = await _hasScheduleConflict(
      workerId: workerId,
      date: selectedStartDate,
    );
    if (hasConflict) {
      throw StateError(
        'You already have an accepted job on this date. Decline this offer or complete the other job first.',
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

    for (final doc in approvedOffersQuery.docs) {
      batch.update(doc.reference, {
        'status': doc.id == applicationId ? 'accepted' : 'declined_by_worker',
        'updatedAt': now,
      });
    }

    batch.set(scheduleDocRef, {
      'workerId': workerId,
      'applicationId': applicationId,
      'jobId': selectedData['jobId'],
      'jobTitle': selectedData['jobTitle'],
      'landownerId': selectedData['landownerId'],
      'landownerName': selectedData['landownerName'],
      'startDate': selectedData['startDate'],
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

  static Future<void> _closeJobIfNoActiveApplications(String jobId) async {
    final activeOrPendingSnapshot = await _applicationsCollection
        .where('jobId', isEqualTo: jobId)
        .where('status', whereIn: ['approved', 'accepted', 'in_progress'])
        .limit(1)
        .get();

    if (activeOrPendingSnapshot.docs.isNotEmpty) {
      return;
    }

    final hasCompletedSnapshot = await _applicationsCollection
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();

    if (hasCompletedSnapshot.docs.isEmpty) {
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

    if (rating < 1 || rating > 5) {
      throw StateError('Rating must be between 1 and 5.');
    }

    final now = FieldValue.serverTimestamp();

    // Always persist the rating first.
    await _ratingsCollection.add({
      'fromUserId': fromId,
      'fromUserName': fromUserName,
      'toUserId': toId,
      'toUserName': toUserName,
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

    final now = FieldValue.serverTimestamp();
    final joinedAt = Timestamp.now();
    await _workerGroupsCollection.add({
      'groupName': trimmedName,
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

  static Future<void> addMemberToGroup({
    required String groupId,
    required String coordinatorId,
    required String memberWorkerId,
  }) async {
    final memberId = memberWorkerId.trim();
    if (memberId.isEmpty) {
      throw StateError('Worker ID is required.');
    }

    final userRef = _firestore.collection('users').doc(memberId);
    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    if (userData == null) {
      throw StateError('Worker not found for this ID.');
    }

    final memberName = (userData['name'] as String?)?.trim();
    final memberPhone = (userData['phone'] as String?)?.trim() ?? '';

    final groupRef = _workerGroupsCollection.doc(groupId);
    await _firestore.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(groupRef);
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

    await groupRef.delete();
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

    if (memberIds.isEmpty) {
      throw StateError('This group has no members.');
    }

    for (final memberId in memberIds) {
      final hasConflict = await _hasScheduleConflict(
        workerId: memberId,
        date: job.startDate,
      );
      if (hasConflict) {
        throw StateError(
          'Group member $memberId has a schedule conflict on this date.',
        );
      }
    }

    final duplicateQuery = await _groupApplicationsCollection
        .where('jobId', isEqualTo: job.id)
        .where('groupId', isEqualTo: groupId)
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty) {
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
      'groupId': groupId,
      'groupName': (groupData['groupName'] as String?) ?? 'Group',
      'coordinatorId': coordinatorId,
      'coordinatorName':
          (groupData['coordinatorName'] as String?) ?? 'Coordinator',
      'landownerId': job.landownerId,
      'landownerName': job.landownerName,
      'memberIds': memberIds,
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
    await _groupApplicationsCollection.doc(groupApplicationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    final memberIds =
        ((appData['memberIds'] as List<dynamic>?) ?? const <dynamic>[])
            .map((id) => id.toString())
            .where((id) => id.isNotEmpty)
            .toList(growable: false);

    if (memberIds.isEmpty) {
      throw StateError('This group has no members to schedule.');
    }

    for (final memberId in memberIds) {
      final hasConflict = await _hasScheduleConflict(
        workerId: memberId,
        date: startDate,
      );
      if (hasConflict) {
        throw StateError(
          'Member $memberId already has an accepted job on this date.',
        );
      }
    }

    final now = FieldValue.serverTimestamp();
    final scheduleDateKey = _scheduleDateKey(startDate);
    final batch = _firestore.batch();

    batch.update(appRef, {'status': 'accepted', 'updatedAt': now});

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
        'scheduleDateKey': scheduleDateKey,
        'status': 'accepted',
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }
}
