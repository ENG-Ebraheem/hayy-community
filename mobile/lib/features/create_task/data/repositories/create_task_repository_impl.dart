import '../../../../core/errors/failures.dart';
import '../../../tasks_home/domain/entities/task.dart';
import '../../domain/entities/create_task_input.dart';
import '../../domain/repositories/create_task_repository.dart';
import '../datasources/create_task_remote_data_source.dart';

class CreateTaskRepositoryImpl implements CreateTaskRepository {
  final CreateTaskRemoteDataSource remote;
  CreateTaskRepositoryImpl(this.remote);
  @override
  Future<Task> createTask(CreateTaskInput input) async {
    try {
      return await remote.createTask(input);
    } catch (e) {
      throw mapDioFailure(e);
    }
  }
}
