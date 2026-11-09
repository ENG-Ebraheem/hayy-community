import '../../../../core/errors/failures.dart';
import '../../../tasks_home/domain/entities/task.dart';
import '../../domain/repositories/task_details_repository.dart';
import '../datasources/task_details_remote_data_source.dart';
class TaskDetailsRepositoryImpl implements TaskDetailsRepository {
  final TaskDetailsRemoteDataSource remote;
  TaskDetailsRepositoryImpl(this.remote);

  @override
  Future<Task> get(int id) async {
    try {
      return await remote.get(id);
    } catch (e) {
      throw mapDioFailure(e);
    }
  }

  @override
  Future<Task> volunteer(int id, String m, {String? volunteerName}) async {
    try {
      return await remote.volunteer(id, m, volunteerName: volunteerName);
    } catch (e) {
      throw mapDioFailure(e);
    }
  }

  @override
  Future<Task> accept(int id, String v) async {
    try {
      return await remote.accept(id, v);
    } catch (e) {
      throw mapDioFailure(e);
    }
  }

  @override
  Future<Task> updateStatus(int id, String s) async {
    try {
      return await remote.updateStatus(id, s);
    } catch (e) {
      throw mapDioFailure(e);
    }
  }
}
