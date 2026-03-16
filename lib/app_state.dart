import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool _debugLogging = true;

enum UserRole { worker, landowner }

enum ApplicationStatus { pending, approved, rejected }

typedef UserID = String;

typedef JobID = String;

typedef ApplicationID = String;

class AppUser {
  final UserID id;
  String name;
  String username;
  String password;
  UserRole role;
  bool verified;
  String nic;
  String contact;
  String profileDescription;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.verified = false,
    this.nic = '',
    this.contact = '',
    this.profileDescription = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'username': username,
    'password': password,
    'role': role.toString().split('.').last,
    'verified': verified,
    'nic': nic,
    'contact': contact,
    'profileDescription': profileDescription,
  };

  static AppUser fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as String,
    name: map['name'] as String,
    username: map['username'] as String,
    password: map['password'] as String,
    role: map['role'] == 'landowner' || map['role'] == 'UserRole.landowner'
        ? UserRole.landowner
        : UserRole.worker,
    verified: map['verified'] as bool? ?? false,
    nic: map['nic'] as String? ?? '',
    contact: map['contact'] as String? ?? '',
    profileDescription: map['profileDescription'] as String? ?? '',
  );
}

class Job {
  final JobID id;
  final UserID postedBy;
  String title;
  String description;
  String location;
  double wage;
  DateTime date;
  bool isOpen;
  final List<Application> applications;
  final List<WorkerSchedule> schedule;

  Job({
    required this.id,
    required this.postedBy,
    required this.title,
    required this.description,
    required this.location,
    required this.wage,
    required this.date,
    this.isOpen = true,
  }) : applications = [],
       schedule = [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'postedBy': postedBy,
    'title': title,
    'description': description,
    'location': location,
    'wage': wage,
    'date': date.toIso8601String(),
    'isOpen': isOpen,
    'applications': applications.map((a) => a.toMap()).toList(),
    'schedule': schedule.map((s) => s.toMap()).toList(),
  };

  static Job fromMap(Map<String, dynamic> map) {
    final job = Job(
      id: map['id'] as String,
      postedBy: map['postedBy'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      location: map['location'] as String,
      wage: (map['wage'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      isOpen: map['isOpen'] as bool? ?? true,
    );

    if (map['applications'] is List) {
      for (final a in map['applications'] as List) {
        job.applications.add(Application.fromMap(Map<String, dynamic>.from(a)));
      }
    }
    if (map['schedule'] is List) {
      for (final s in map['schedule'] as List) {
        job.schedule.add(WorkerSchedule.fromMap(Map<String, dynamic>.from(s)));
      }
    }
    return job;
  }
}

class Application {
  final ApplicationID id;
  final JobID jobId;
  final UserID workerId;
  final String workerName;
  final DateTime submittedAt;
  ApplicationStatus status;
  String feedback;

  Application({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.workerName,
    DateTime? submittedAt,
    this.status = ApplicationStatus.pending,
    this.feedback = '',
  }) : submittedAt = submittedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'jobId': jobId,
    'workerId': workerId,
    'workerName': workerName,
    'submittedAt': submittedAt.toIso8601String(),
    'status': status.toString().split('.').last,
    'feedback': feedback,
  };

  static Application fromMap(Map<String, dynamic> map) => Application(
    id: map['id'] as String,
    jobId: map['jobId'] as String,
    workerId: map['workerId'] as String,
    workerName: map['workerName'] as String,
    submittedAt: DateTime.parse(map['submittedAt'] as String),
    status: map['status'] == 'approved'
        ? ApplicationStatus.approved
        : map['status'] == 'rejected'
        ? ApplicationStatus.rejected
        : ApplicationStatus.pending,
    feedback: map['feedback'] as String? ?? '',
  );
}

class WorkerSchedule {
  final UserID workerId;
  final JobID jobId;
  final DateTime date;

  WorkerSchedule({
    required this.workerId,
    required this.jobId,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'workerId': workerId,
    'jobId': jobId,
    'date': date.toIso8601String(),
  };

  static WorkerSchedule fromMap(Map<String, dynamic> map) => WorkerSchedule(
    workerId: map['workerId'] as String,
    jobId: map['jobId'] as String,
    date: DateTime.parse(map['date'] as String),
  );
}

class TaskProgressRecord {
  final JobID jobId;
  final UserID workerId;
  int quantity;
  String note;
  DateTime date;

  TaskProgressRecord({
    required this.jobId,
    required this.workerId,
    required this.quantity,
    required this.note,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'jobId': jobId,
    'workerId': workerId,
    'quantity': quantity,
    'note': note,
    'date': date.toIso8601String(),
  };

  static TaskProgressRecord fromMap(Map<String, dynamic> map) =>
      TaskProgressRecord(
        jobId: map['jobId'] as String,
        workerId: map['workerId'] as String,
        quantity: map['quantity'] as int,
        note: map['note'] as String,
        date: DateTime.parse(map['date'] as String),
      );
}

class Rating {
  final UserID by;
  final UserID forUser;
  final int score;
  final String comment;
  final DateTime date;

  Rating({
    required this.by,
    required this.forUser,
    required this.score,
    required this.comment,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'by': by,
    'forUser': forUser,
    'score': score,
    'comment': comment,
    'date': date.toIso8601String(),
  };

  static Rating fromMap(Map<String, dynamic> map) => Rating(
    by: map['by'] as String,
    forUser: map['forUser'] as String,
    score: map['score'] as int,
    comment: map['comment'] as String,
    date: DateTime.parse(map['date'] as String),
  );
}

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();

  AppState._internal();

  final List<AppUser> users = [];
  final List<Job> jobs = [];
  final List<TaskProgressRecord> progressRecords = [];
  final List<Rating> ratings = [];

  AppUser? currentUser;

  void initializeDemoData() {
    if (users.isNotEmpty) return;
    users.add(
      AppUser(
        id: 'landowner',
        name: 'Landowner Kumara',
        username: 'landowner',
        password: 'landowner',
        role: UserRole.landowner,
        verified: true,
      ),
    );
    users.add(
      AppUser(
        id: 'worker',
        name: 'Worker Silva',
        username: 'worker',
        password: 'worker',
        role: UserRole.worker,
        verified: true,
      ),
    );
    jobs.add(
      Job(
        id: 'job-1',
        postedBy: 'landowner',
        title: 'Cinnamon Harvester',
        description: 'Harvest cinnamon bark from mature trees in Plantation A',
        location: 'Plantation A',
        wage: 500,
        date: DateTime.now().add(const Duration(days: 2)),
      ),
    );
    jobs.add(
      Job(
        id: 'job-2',
        postedBy: 'landowner',
        title: 'Cinnamon Planter',
        description: 'Plant cinnamon seedlings in Plantation B',
        location: 'Plantation B',
        wage: 400,
        date: DateTime.now().add(const Duration(days: 3)),
      ),
    );
  }

  Future<void> loadFromStorage() async {
    if (_debugLogging) {
      debugPrint('AppState: loadFromStorage is skipped (in-memory only)');
    }
  }

  Future<void> saveToStorage() async {
    if (_debugLogging) {
      debugPrint('AppState: saveToStorage is skipped (in-memory only)');
    }
  }

  Future<void> _saveAndNotify() async {
    await saveToStorage();
    notifyListeners();
  }

  Future<AppUser?> login(String username, String password) async {
    final filtered = users.where(
      (u) =>
          u.username.toLowerCase() == username.toLowerCase() &&
          u.password == password,
    );
    if (filtered.isEmpty) return null;
    final user = filtered.first;
    currentUser = user;
    await _saveAndNotify();
    return user;
  }

  Future<AppUser?> register(
    String name,
    String username,
    String password,
    String contact,
    UserRole role,
  ) async {
    final normalizedUsername = username.toLowerCase();
    final normalizedContact = contact.toLowerCase();

    if (users.any((u) => u.username.toLowerCase() == normalizedUsername)) {
      return null;
    }
    if (users.any((u) => u.contact.toLowerCase() == normalizedContact)) {
      return null;
    }
    final user = AppUser(
      id: 'u-${users.length + 1}',
      name: name,
      username: normalizedUsername,
      password: password,
      role: role,
      verified: role == UserRole.landowner,
      contact: contact,
    );
    users.add(user);
    await _saveAndNotify();
    return user;
  }

  Future<bool> postJob({
    required UserID postedBy,
    required String title,
    required String description,
    required String location,
    required double wage,
    required DateTime date,
  }) async {
    final job = Job(
      id: 'job-${jobs.length + 1}',
      postedBy: postedBy,
      title: title,
      description: description,
      location: location,
      wage: wage,
      date: date,
    );
    jobs.add(job);
    await _saveAndNotify();
    return true;
  }

  Future<bool> applyToJob({
    required JobID jobId,
    required UserID workerId,
  }) async {
    final jobList = jobs.where((j) => j.id == jobId);
    if (jobList.isEmpty) return false;
    final job = jobList.first;
    if (!job.isOpen) return false;
    if (job.applications.any((a) => a.workerId == workerId)) return false;

    final userList = users.where((u) => u.id == workerId);
    if (userList.isEmpty) return false;
    final user = userList.first;

    job.applications.add(
      Application(
        id: 'ap-${job.applications.length + 1}',
        jobId: job.id,
        workerId: workerId,
        workerName: user.name,
      ),
    );
    await _saveAndNotify();
    return true;
  }

  Future<bool> approveApplication({
    required JobID jobId,
    required ApplicationID applicationId,
  }) async {
    final jobsWithId = jobs.where((j) => j.id == jobId);
    if (jobsWithId.isEmpty) return false;
    final job = jobsWithId.first;
    final apps = job.applications.where((a) => a.id == applicationId);
    if (apps.isEmpty) return false;
    final app = apps.first;
    if (app.status != ApplicationStatus.pending) return false;
    app.status = ApplicationStatus.approved;

    final hasConflict = scheduleConflict(app.workerId, job.date);
    if (!hasConflict) {
      job.schedule.add(
        WorkerSchedule(workerId: app.workerId, jobId: job.id, date: job.date),
      );
    }
    await _saveAndNotify();
    return true;
  }

  Future<bool> rejectApplication({
    required JobID jobId,
    required ApplicationID applicationId,
  }) async {
    final jobsWithId = jobs.where((j) => j.id == jobId);
    if (jobsWithId.isEmpty) return false;
    final job = jobsWithId.first;
    final apps = job.applications.where((a) => a.id == applicationId);
    if (apps.isEmpty) return false;
    final app = apps.first;
    if (app.status != ApplicationStatus.pending) return false;
    app.status = ApplicationStatus.rejected;
    await _saveAndNotify();
    return true;
  }

  bool scheduleConflict(UserID workerId, DateTime jobDate) {
    for (final j in jobs) {
      for (final s in j.schedule) {
        if (s.workerId == workerId &&
            s.date.year == jobDate.year &&
            s.date.month == jobDate.month &&
            s.date.day == jobDate.day) {
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> addProgress({
    required JobID jobId,
    required UserID workerId,
    required int quantity,
    required String note,
  }) async {
    progressRecords.add(
      TaskProgressRecord(
        jobId: jobId,
        workerId: workerId,
        quantity: quantity,
        note: note,
      ),
    );
    await _saveAndNotify();
    return true;
  }

  Future<void> giveRating({
    required UserID from,
    required UserID to,
    required int score,
    required String comment,
  }) async {
    ratings.add(Rating(by: from, forUser: to, score: score, comment: comment));
    await _saveAndNotify();
  }

  double averageRatingFor(UserID userId) {
    final userRatings = ratings.where((r) => r.forUser == userId);
    if (userRatings.isEmpty) return 0;
    return userRatings.map((r) => r.score).reduce((a, b) => a + b) /
        userRatings.length;
  }

  Future<void> logout() async {
    currentUser = null;
    await _saveAndNotify();
  }
}
