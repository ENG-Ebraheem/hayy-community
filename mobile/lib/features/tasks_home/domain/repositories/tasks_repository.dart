import '../entities/task.dart';

abstract class TasksRepository {
  Future<List<Task>> getTasks({
    String? search,
    String? category,
    String? status,
    String? ownerId,
    String? volunteerId,
  });
  Future<Task> getTask(int id);
}
