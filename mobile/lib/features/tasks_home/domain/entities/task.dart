import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final int id;
  final String ownerId;
  final String? ownerName;
  final String? assignedVolunteerId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String status;
  final bool isRated;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final List<TaskApplication> applications;

  const Task({
    required this.id,
    required this.ownerId,
    this.ownerName,
    this.assignedVolunteerId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    this.isRated = false,
    this.dueDate,
    this.createdAt,
    this.applications = const [],
  });

  bool get isOpen => status == 'OPEN';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  @override
  List<Object?> get props => [
        id,
        ownerId,
        ownerName,
        assignedVolunteerId,
        title,
        description,
        category,
        location,
        status,
        isRated,
        dueDate,
        createdAt,
        applications,
      ];
}

class TaskApplication extends Equatable {
  final int id;
  final int taskId;
  final String volunteerId;
  final String? volunteerName;
  final String status;
  final String? message;

  const TaskApplication({
    required this.id,
    required this.taskId,
    required this.volunteerId,
    this.volunteerName,
    required this.status,
    this.message,
  });

  @override
  List<Object?> get props => [id, taskId, volunteerId, volunteerName, status, message];
}
