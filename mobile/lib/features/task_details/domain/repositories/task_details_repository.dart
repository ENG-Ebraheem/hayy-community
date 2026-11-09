import '../../../tasks_home/domain/entities/task.dart';
abstract class TaskDetailsRepository {
  Future<Task> get(int id);
  Future<Task> volunteer(int id, String message, {String? volunteerName});
  Future<Task> accept(int id, String volunteerId);
  Future<Task> updateStatus(int id, String status);
}
