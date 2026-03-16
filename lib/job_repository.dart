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

  factory JobRecord.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return JobRecord(
      id: snapshot.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      jobType: (data['jobType'] as String?) ?? '',
      paymentRate: ((data['paymentRate'] as num?) ?? 0).toDouble(),
      requiredWorkers: ((data['requiredWorkers'] as num?) ?? 0).toInt(),
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

class JobRepository {
  JobRepository._();

  static const Duration _approvalDecisionWindow = Duration(hours: 24);

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('jobs');

  static CollectionReference<Map<String, dynamic>> get _applicationsCollection =>
      _firestore.collection('applications');

  static CollectionReference<Map<String, dynamic>> get _schedulesCollection =>
      _firestore.collection('schedules');

  static CollectionReference<Map<String, dynamic>> get _taskProgressCollection =>
      _firestore.collection('task_progress');

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
            (sum, doc) => sum + (((doc.data()['quillCount'] as num?) ?? 0).toInt()),
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
    return _jobsCollection
        .where('status', isEqualTo: 'open')
        .orderBy('startDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(JobRecord.fromSnapshot)
              .toList(growable: false),
        );
  }

  static Stream<List<JobRecord>> streamJobsForLandowner(String landownerId) {
    return _jobsCollection
        .where('landownerId', isEqualTo: landownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(JobRecord.fromSnapshot)
              .toList(growable: false),
        );
  }

  static Stream<List<WorkerApplicationRecord>> streamApplicationsForWorker(
    String workerId,
  ) {
    return _applicationsCollection
        .where('workerId', isEqualTo: workerId)
        .where('status', whereIn: ['approved', 'accepted', 'completed', 'expired'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkerApplicationRecord.fromSnapshot)
              .toList(growable: false),
        );
  }

  static Stream<List<WorkerApplicationRecord>> streamApplicationsForJob(
    String jobId,
  ) {
    return _applicationsCollection
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkerApplicationRecord.fromSnapshot)
              .toList(growable: false),
        );
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
        batch.update(doc.reference, {
          'status': 'expired',
          'updatedAt': now,
        });
      }
    }

    if (changed) {
      await batch.commit();
    }
  }

  static Future<void> expirePendingApprovalsForLandowner(String landownerId) async {
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
        batch.update(doc.reference, {
          'status': 'expired',
          'updatedAt': now,
        });
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

    final decisionDeadline =
        (selectedData['decisionDeadline'] as Timestamp?)?.toDate();
    if (_isExpiredDecision(decisionDeadline)) {
      await selectedRef.update({
        'status': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      throw StateError('This offer has expired. Ask the landowner to approve again.');
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
    if (!(status == 'accepted' || status == 'completed')) {
      throw StateError('Progress can only be added to accepted jobs.');
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
      transaction.update(jobRef, {
        'totalQuillCount': currentTotal + quillCount,
        'updatedAt': now,
      });
    });
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

    if (appData['status'] != 'accepted') {
      throw StateError('Only accepted jobs can be marked as completed.');
    }

    final now = FieldValue.serverTimestamp();

    final scheduleQuery = await _schedulesCollection
        .where('applicationId', isEqualTo: applicationId)
        .limit(1)
        .get();

    final batch = _firestore.batch();
    batch.update(appRef, {
      'status': 'completed',
      'updatedAt': now,
    });

    if (scheduleQuery.docs.isNotEmpty) {
      batch.update(scheduleQuery.docs.first.reference, {
        'status': 'completed',
        'updatedAt': now,
      });
    }

    await batch.commit();
  }
}