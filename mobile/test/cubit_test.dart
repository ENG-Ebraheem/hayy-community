import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/app_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mobile/features/tasks_home/domain/entities/task.dart';
import 'package:mobile/features/tasks_home/domain/repositories/tasks_repository.dart';
import 'package:mobile/features/tasks_home/presentation/cubits/tasks_home_cubit.dart';

class FakeTasksRepository implements TasksRepository {
  final List<Task> source;
  FakeTasksRepository(this.source);

  @override
  Future<Task> getTask(int id) async => source.firstWhere((task) => task.id == id);

  @override
  Future<List<Task>> getTasks({
    String? search,
    String? category,
    String? status,
    String? ownerId,
    String? volunteerId,
  }) async =>
      source.where((task) {
        final matchesSearch = search == null || task.title.contains(search);
        final matchesCategory = category == null || category == 'الكل' || task.category == category;
        final matchesOwner = ownerId == null || task.ownerId == ownerId;
        return matchesSearch && matchesCategory && matchesOwner;
      }).toList();
}

class FakeAuthRepository implements AuthRepository {
  @override Stream<AppUser?> authStateChanges() => const Stream<AppUser?>.empty();
  @override Future<AppUser> login(String email, String password) async => const AppUser(uid: 'u1');
  @override Future<AppUser> register(String email, String password) async => const AppUser(uid: 'u1');
  @override Future<void> logout() async {}
}

void main() {
  final task = Task(
    id: 1,
    ownerId: 'owner',
    title: 'توسيل',
    description: 'desc',
    category: 'توصيل',
    location: 'حي',
    status: 'OPEN',
  );

  test('TasksHomeCubit emits loaded tasks and applies category filter', () async {
    final cubit = TasksHomeCubit(FakeTasksRepository([task]));
    await cubit.load();
    expect(cubit.state, isA<TasksHomeLoaded>());
    await cubit.setCategory('توصيل');
    expect((cubit.state as TasksHomeLoaded).tasks.single.id, 1);
    await cubit.close();
  });

  test('AuthCubit emits authenticated state after demo session starts', () async {
    final cubit = AuthCubit(FakeAuthRepository());
    await cubit.startDemo('user@test.com');
    expect(cubit.state, isA<AuthAuthenticated>());
    expect((cubit.state as AuthAuthenticated).user.uid, startsWith('demo-'));
    await cubit.close();
  });
}
