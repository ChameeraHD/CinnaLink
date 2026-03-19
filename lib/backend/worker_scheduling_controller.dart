import 'job_repository.dart';

class WorkerSchedulingController {
  const WorkerSchedulingController();

  String readableError(Object error) {
    return error.toString().replaceFirst('Bad state: ', '').trim();
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) {
    return JobRepository.updateApplicationStatus(
      applicationId: applicationId,
      status: status,
    );
  }

  Future<void> updateGroupApplicationStatus({
    required String groupApplicationId,
    required String status,
  }) {
    return JobRepository.updateGroupApplicationStatus(
      groupApplicationId: groupApplicationId,
      status: status,
    );
  }

  Future<void> acceptGroupApplication({
    required String landownerId,
    required String groupApplicationId,
  }) {
    return JobRepository.acceptGroupApplicationDecision(
      landownerId: landownerId,
      groupApplicationId: groupApplicationId,
    );
  }
}
