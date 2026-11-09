import '../../../tasks_home/domain/entities/task.dart';
import '../entities/create_task_input.dart';
abstract class CreateTaskRepository { Future<Task> createTask(CreateTaskInput input); }
