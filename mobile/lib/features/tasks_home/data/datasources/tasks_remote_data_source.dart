import 'package:dio/dio.dart';
import '../models/task_model.dart';

class TasksRemoteDataSource {
  final Dio dio;
  TasksRemoteDataSource(this.dio);

  Future<List<TaskModel>> getTasks({
    String? status,
    String? category,
    String? search,
    String? ownerId,
    String? volunteerId,
  }) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (category != null && category != 'الكل') query['category'] = category;
    if (search != null && search.trim().isNotEmpty)
      query['search'] = search.trim();
    if (ownerId != null) query['owner_id'] = ownerId;
    if (volunteerId != null) query['volunteer_id'] = volunteerId;

    final response = await dio.get('/tasks', queryParameters: query);
    final rawData = response.data;
    final data = rawData is Map && rawData.containsKey('data')
        ? rawData['data']
        : rawData;

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => TaskModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<TaskModel> getTask(int id) async {
    final response = await dio.get('/tasks/$id');
    final rawData = response.data;
    final data = rawData is Map && rawData.containsKey('data')
        ? rawData['data']
        : rawData;
    return TaskModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
