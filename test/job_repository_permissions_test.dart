import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('job acceptance rules validate the accepted worker on the update payload', () async {
    final rules = await File('firestore.rules').readAsString();

    expect(rules, contains('function isAcceptedWorkerForJob(jobId)'));
    expect(rules, contains('request.resource.data.acceptedWorkerId == request.auth.uid'));
    expect(rules, contains('request.resource.data.acceptedWorkerIds.hasAny([request.auth.uid])'));
  });
}
