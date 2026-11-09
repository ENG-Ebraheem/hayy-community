import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.ownerId,
    super.ownerName,
    super.assignedVolunteerId,
    required super.title,
    required super.description,
    required super.category,
    required super.location,
    required super.status,
    super.isRated,
    super.dueDate,
    super.createdAt,
    super.applications,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawApplications = json['applications'];
    return TaskModel(
      id: _int(json['id']),
      ownerId: '${json['owner_id'] ?? ''}',
      ownerName: json['owner_name']?.toString(),
      assignedVolunteerId: json['assigned_volunteer_id']?.toString(),
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? ''}',
      location: '${json['location'] ?? ''}',
      status: '${json['status'] ?? 'OPEN'}',
      isRated: json['is_rated'] == true,
      dueDate: _date(json['due_date']),
      createdAt: _date(json['created_at']),
      applications: rawApplications is List
          ? rawApplications
              .whereType<Map>()
              .map((item) => TaskApplicationModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  static int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
  static DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse('$value');
}

class TaskApplicationModel extends TaskApplication {
  const TaskApplicationModel({
    required super.id,
    required super.taskId,
    required super.volunteerId,
    super.volunteerName,
    required super.status,
    super.message,
  });

  factory TaskApplicationModel.fromJson(Map<String, dynamic> json) {
    return TaskApplicationModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      taskId: json['task_id'] is int
          ? json['task_id']
          : int.tryParse('${json['task_id']}') ?? 0,
      volunteerId: '${json['volunteer_id'] ?? ''}',
      volunteerName: json['volunteer_name']?.toString(),
      status: '${json['status'] ?? 'PENDING'}',
      message: json['message']?.toString(),
    );
  }
}
