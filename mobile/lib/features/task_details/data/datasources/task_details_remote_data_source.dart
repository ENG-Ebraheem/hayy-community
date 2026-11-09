import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../tasks_home/data/models/task_model.dart';
class TaskDetailsRemoteDataSource {
  final Dio dio;
  TaskDetailsRemoteDataSource(this.dio);

  Future<TaskModel> get(int id) async {
    final r = await dio.get(ApiConstants.taskDetails(id));
    return TaskModel.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
  }

  Future<TaskModel> volunteer(int id, String message, {String? volunteerName}) async {
    await dio.post(ApiConstants.volunteerTask(id), data: {
      'message': message,
      if (volunteerName != null && volunteerName.isNotEmpty) 'volunteer_name': volunteerName,
    });
    return get(id);
  }

  Future<TaskModel> accept(int id, String volunteerId) async {
    final r = await dio.post(ApiConstants.acceptVolunteer(id), data: {'volunteer_id': volunteerId});
    return TaskModel.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
  }

  Future<TaskModel> updateStatus(int id, String status) async {
    final r = await dio.patch(ApiConstants.updateTaskStatus(id), data: {'status': status});
    return TaskModel.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
  }
}
