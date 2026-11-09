import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../tasks_home/domain/entities/task.dart';
import '../../domain/entities/create_task_input.dart';
import '../../domain/repositories/create_task_repository.dart';
sealed class CreateTaskState {}
class CreateTaskInitial extends CreateTaskState {}
class CreateTaskLoading extends CreateTaskState {}
class CreateTaskSuccess extends CreateTaskState { final Task task; CreateTaskSuccess(this.task); }
class CreateTaskError extends CreateTaskState { final String message; CreateTaskError(this.message); }
class CreateTaskCubit extends Cubit<CreateTaskState> { final CreateTaskRepository repo; CreateTaskCubit(this.repo):super(CreateTaskInitial()); Future<void> submit(CreateTaskInput input) async { emit(CreateTaskLoading()); try{emit(CreateTaskSuccess(await repo.createTask(input)));}catch(e){final f=e is Failure?e:mapDioFailure(e);emit(CreateTaskError(f.message));} } }
