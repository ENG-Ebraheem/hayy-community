import '../../../../core/errors/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../datasources/tasks_remote_data_source.dart';

class TasksRepositoryImpl implements TasksRepository {
  final TasksRemoteDataSource remote;
  TasksRepositoryImpl(this.remote);

  @override
  Future<List<Task>> getTasks({
    String? search,
    String? category,
    String? status,
    String? ownerId,
    String? volunteerId,
  }) async {
    try {
      return await remote.getTasks(
        search: search,
        category: category,
        status: status,
        ownerId: ownerId,
        volunteerId: volunteerId,
      );
    } catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<Task> getTask(int id) async {
    try {
      return await remote.getTask(id);
    } catch (error) {
      throw mapDioFailure(error);
    }
  }
}
