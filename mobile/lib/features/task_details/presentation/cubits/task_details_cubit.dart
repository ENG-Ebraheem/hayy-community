import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../tasks_home/domain/entities/task.dart';
import '../../domain/repositories/task_details_repository.dart';

sealed class TaskDetailsState {
  final Task? task;
  const TaskDetailsState({this.task});
}

class TaskDetailsInitial extends TaskDetailsState {
  const TaskDetailsInitial() : super(task: null);
}

class TaskDetailsLoading extends TaskDetailsState {
  const TaskDetailsLoading({super.task});
}

class TaskDetailsLoaded extends TaskDetailsState {
  final String? successMessage;
  const TaskDetailsLoaded(Task task, {this.successMessage}) : super(task: task);
}

class TaskDetailsError extends TaskDetailsState {
  final String message;
  const TaskDetailsError(this.message, {super.task});
}

class TaskDetailsCubit extends Cubit<TaskDetailsState> {
  final TaskDetailsRepository repo;

  TaskDetailsCubit(this.repo) : super(const TaskDetailsInitial());

  Future<void> load(int id) async {
    final currentTask = state.task;
    emit(TaskDetailsLoading(task: currentTask));
    try {
      final task = await repo.get(id);
      emit(TaskDetailsLoaded(task));
    } catch (e) {
      final f = e is Failure ? e : mapDioFailure(e);
      emit(TaskDetailsError(f.message, task: currentTask));
    }
  }

  Future<void> volunteer(String message, {String? volunteerName}) async {
    final currentTask = state.task;
    if (currentTask == null) return;
    emit(TaskDetailsLoading(task: currentTask));
    try {
      final updatedTask = await repo.volunteer(currentTask.id, message, volunteerName: volunteerName);
      emit(TaskDetailsLoaded(
        updatedTask,
        successMessage: 'تم إرسال طلب التطوع بنجاح',
      ));
    } catch (e) {
      final f = e is Failure ? e : mapDioFailure(e);
      emit(TaskDetailsError(f.message, task: currentTask));
    }
  }

  Future<void> accept(String uid) async {
    final currentTask = state.task;
    if (currentTask == null) return;
    emit(TaskDetailsLoading(task: currentTask));
    try {
      final updatedTask = await repo.accept(currentTask.id, uid);
      emit(TaskDetailsLoaded(
        updatedTask,
        successMessage: 'تم قبول طلب التطوع بنجاح',
      ));
    } catch (e) {
      final f = e is Failure ? e : mapDioFailure(e);
      emit(TaskDetailsError(f.message, task: currentTask));
    }
  }

  Future<void> updateStatus(String status) async {
    final currentTask = state.task;
    if (currentTask == null) return;
    emit(TaskDetailsLoading(task: currentTask));
    try {
      final updatedTask = await repo.updateStatus(currentTask.id, status);
      final msg = status == 'COMPLETED'
          ? 'تم إتمام المهمة بنجاح'
          : status == 'CANCELLED'
              ? 'تم إلغاء المهمة'
              : 'تم تحديث حالة المهمة بنجاح';
      emit(TaskDetailsLoaded(
        updatedTask,
        successMessage: msg,
      ));
    } catch (e) {
      final f = e is Failure ? e : mapDioFailure(e);
      emit(TaskDetailsError(f.message, task: currentTask));
    }
  }
}

