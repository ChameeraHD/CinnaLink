class Job {
  final String title;
  final String type;
  final String description;
  final String location;
  final int workers;
  final double wage;
  final DateTime date;
  final String phoneNumber;

  Job({
    required this.title,
    required this.type,
    required this.description,
    required this.location,
    required this.workers,
    required this.wage,
    required this.date,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'description': description,
      'location': location,
      'workers': workers,
      'wage': wage,
      'date': date.toIso8601String(),
      'phoneNumber': phoneNumber,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      title: map['title'],
      type: map['type'],
      description: map['description'],
      location: map['location'],
      workers: map['workers'],
      wage: map['wage'],
      date: DateTime.parse(map['date']),
      phoneNumber: map['phoneNumber'],
    );
  }
}
