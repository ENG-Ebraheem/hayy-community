import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/session/app_session.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

import '../../../../core/storage/local_storage.dart';

sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthChecking extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthAuthenticated extends AuthState {
  final AppUser user;
  AuthAuthenticated(this.user);
}
class AuthLoading extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  final LocalStorage? localStorage;
  StreamSubscription<AppUser?>? _subscription;

  AuthCubit(this.repository, {this.localStorage}) : super(AuthInitial());

  void checkSession() {
    emit(AuthChecking());
    _subscription?.cancel();
    _subscription = repository.authStateChanges().listen(
      (user) {
        if (user == null) {
          localStorage?.clearLastUserUid();
          emit(AuthUnauthenticated());
        } else {
          localStorage?.saveLastUserUid(user.uid);
          emit(AuthAuthenticated(user));
        }
      },
      onError: (_) {
        localStorage?.clearLastUserUid();
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await repository.login(email, password);
      emit(AuthAuthenticated(user));
    } catch (error) {
      final failure = error is Failure ? error : AuthFailure('تعذر تسجيل الدخول.');
      emit(AuthError(failure.message));
    }
  }

  Future<void> register(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await repository.register(email, password);
      emit(AuthAuthenticated(user));
    } catch (error) {
      final failure = error is Failure ? error : AuthFailure('تعذر إنشاء الحساب.');
      emit(AuthError(failure.message));
    }
  }

  Future<void> startDemo(String name) async {
    final safeName = name.trim().isEmpty ? 'demo-user' : name.trim();
    final uid = 'demo-${safeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().millisecondsSinceEpoch}';
    AppSession.instance.startDemo(uid: uid);
    emit(AuthAuthenticated(AppUser(uid: uid, email: '$uid@example.local', displayName: safeName)));
  }

  Future<void> logout() async {
    await repository.logout();
    await localStorage?.clearLastUserUid();
    AppSession.instance.clear();
    emit(AuthUnauthenticated());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
