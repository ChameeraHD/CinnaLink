class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<void> initialize() async {}
}

/*
            contact: json['contact'] as String? ?? '',
            profileDescription: json['profileDescription'] as String? ?? '',
          ),
        )
        .toList();
  }

  // --- Jobs ---
  Future<void> createJob(Job job) async {
    final db = await instance.database;
    await db.insert('jobs', {
      'id': job.id,
      'postedBy': job.postedBy,
      'title': job.title,
      'description': job.description,
      'location': job.location,
      'wage': job.wage,
      'date': job.date.toIso8601String(),
      'isOpen': job.isOpen ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // update apps
    for (var app in job.applications) {
      await createApplication(app);
    }
    // update schedule
    for (var sched in job.schedule) {
      await createSchedule(sched);
    }
  }

  Future<List<Job>> readAllJobs() async {
    final db = await instance.database;
    final result = await db.query('jobs');

    List<Job> jobs = [];
    for (var json in result) {
      final job = Job(
        id: json['id'] as String,
        postedBy: json['postedBy'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        location: json['location'] as String,
        wage: json['wage'] as double,
        date: DateTime.parse(json['date'] as String),
        isOpen: (json['isOpen'] as int) == 1,
      );

      final appsJson = await db.query(
        'applications',
        where: 'jobId = ?',
        whereArgs: [job.id],
      );
      for (var aJson in appsJson) {
        job.applications.add(
          Application(
            id: aJson['id'] as String,
            jobId: aJson['jobId'] as String,
            workerId: aJson['workerId'] as String,
            workerName: aJson['workerName'] as String,
            submittedAt: DateTime.parse(aJson['submittedAt'] as String),
            status: aJson['status'] == 'approved'
                ? ApplicationStatus.approved
                : (aJson['status'] == 'rejected'
                      ? ApplicationStatus.rejected
                      : ApplicationStatus.pending),
            feedback: aJson['feedback'] as String? ?? '',
          ),
        );
      }

      final schedJson = await db.query(
        'schedules',
        where: 'jobId = ?',
        whereArgs: [job.id],
      );
      for (var sJson in schedJson) {
        job.schedule.add(
          WorkerSchedule(
            workerId: sJson['workerId'] as String,
            jobId: sJson['jobId'] as String,
            date: DateTime.parse(sJson['date'] as String),
          ),
        );
      }
      jobs.add(job);
    }
    return jobs;
  }

  // --- Applications ---
  Future<void> createApplication(Application app) async {
    final db = await instance.database;
    await db.insert('applications', {
      'id': app.id,
      'jobId': app.jobId,
      'workerId': app.workerId,
      'workerName': app.workerName,
      'submittedAt': app.submittedAt.toIso8601String(),
      'status': app.status.toString().split('.').last,
      'feedback': app.feedback,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Schedules ---
  Future<void> createSchedule(WorkerSchedule schedule) async {
    final db = await instance.database;
    await db.insert('schedules', {
      'workerId': schedule.workerId,
      'jobId': schedule.jobId,
      'date': schedule.date.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // --- Progress Records ---
  Future<void> createProgressRecord(TaskProgressRecord record) async {
    final db = await instance.database;
    await db.insert('progress_records', {
      'jobId': record.jobId,
      'workerId': record.workerId,
      'quantity': record.quantity,
      'note': record.note,
      'date': record.date.toIso8601String(),
    });
  }

  Future<List<TaskProgressRecord>> readAllProgressRecords() async {
    final db = await instance.database;
    final result = await db.query('progress_records');
    return result
        .map(
          (json) => TaskProgressRecord(
            jobId: json['jobId'] as String,
            workerId: json['workerId'] as String,
            quantity: json['quantity'] as int,
            note: json['note'] as String,
            date: DateTime.parse(json['date'] as String),
          ),
        )
        .toList();
  }

  // --- Ratings ---
  Future<void> createRating(Rating rating) async {
    final db = await instance.database;
    await db.insert('ratings', {
      'by': rating.by,
      'forUser': rating.forUser,
      'score': rating.score,
      'comment': rating.comment,
      'date': rating.date.toIso8601String(),
    });
  }

  Future<List<Rating>> readAllRatings() async {
    final db = await instance.database;
    final result = await db.query('ratings');
    return result
        .map(
          (json) => Rating(
            by: json['by'] as String,
            forUser: json['forUser'] as String,
            score: json['score'] as int,
            comment: json['comment'] as String,
            date: DateTime.parse(json['date'] as String),
          ),
        )
        .toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
*/
