import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/tasks_repository.dart';

import '../../../../core/storage/local_storage.dart';

sealed class TasksHomeState {}

class TasksHomeInitial extends TasksHomeState {}

class TasksHomeLoading extends TasksHomeState {}

class TasksHomeLoaded extends TasksHomeState {
  final List<Task> tasks;
  final String? search;
  final String category;
  final String sortBy;
  TasksHomeLoaded(
    this.tasks, {
    this.search,
    this.category = 'الكل',
    this.sortBy = 'newest',
  });
}

class TasksHomeError extends TasksHomeState {
  final String message;
  TasksHomeError(this.message);
}

class TasksHomeCubit extends Cubit<TasksHomeState> {
  final TasksRepository repository;
  final LocalStorage? localStorage;
  String? _search;
  String _category = 'الكل';
  String _sortBy = 'newest';

  TasksHomeCubit(this.repository, {this.localStorage}) : super(TasksHomeInitial()) {
    if (localStorage != null) {
      _category = localStorage!.getLastCategory();
      _sortBy = localStorage!.getLastSortBy();
    }
  }

  Future<void> load() async {
    emit(TasksHomeLoading());
    await _fetch(showLoading: false);
  }

  Future<void> refresh() => _fetch(showLoading: false);

  Future<void> setSearch(String value) async {
    _search = value;
    await _fetch(showLoading: true);
  }

  Future<void> setCategory(String value) async {
    _category = value;
    localStorage?.saveLastCategory(value);
    await _fetch(showLoading: true);
  }

  Future<void> setSortBy(String value) async {
    _sortBy = value;
    localStorage?.saveLastSortBy(value);
    await _fetch(showLoading: false);
  }

  Future<void> _fetch({required bool showLoading}) async {
    if (showLoading) emit(TasksHomeLoading());
    try {
      final tasks = await repository.getTasks(
        search: _search,
        category: _category,
      );
      final sortedTasks = _applySorting(tasks, _sortBy);
      emit(
        TasksHomeLoaded(
          sortedTasks,
          search: _search,
          category: _category,
          sortBy: _sortBy,
        ),
      );
    } catch (error) {
      final failure = error is Failure ? error : mapDioFailure(error);
      emit(TasksHomeError(failure.message));
    }
  }

  List<Task> _applySorting(List<Task> list, String sortBy) {
    final copy = List<Task>.from(list);
    switch (sortBy) {
      case 'oldest':
        copy.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          return aDate.compareTo(bDate);
        });
        break;
      case 'due_date':
        copy.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'open_first':
        copy.sort((a, b) {
          if (a.isOpen && !b.isOpen) return -1;
          if (!a.isOpen && b.isOpen) return 1;
          return 0;
        });
        break;
      case 'newest':
      default:
        copy.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2099);
          final bDate = b.createdAt ?? DateTime(2099);
          return bDate.compareTo(aDate);
        });
        break;
    }
    return copy;
  }
}
