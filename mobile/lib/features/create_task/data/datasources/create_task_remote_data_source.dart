import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../tasks_home/data/models/task_model.dart';
import '../../domain/entities/create_task_input.dart';

class CreateTaskRemoteDataSource {
  final Dio dio;
  CreateTaskRemoteDataSource(this.dio);
  Future<TaskModel> createTask(CreateTaskInput input) async {
    final r = await dio.post(ApiConstants.tasks, data: input.toJson());
    return TaskModel.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
  }
}
