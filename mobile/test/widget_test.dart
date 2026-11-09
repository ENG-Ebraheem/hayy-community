import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/auth/domain/entities/app_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/cubits/auth_cubit.dart';

class _FakeAuthRepository implements AuthRepository {
  @override Stream<AppUser?> authStateChanges() => Stream<AppUser?>.value(null);
  @override Future<AppUser> login(String email, String password) => throw UnimplementedError();
  @override Future<AppUser> register(String email, String password) => throw UnimplementedError();
  @override Future<void> logout() async {}
}

void main() {
  testWidgets('HayyApp shows the Firebase authentication entry point', (tester) async {
    final authCubit = AuthCubit(_FakeAuthRepository());
    authCubit.emit(AuthUnauthenticated());
    await tester.pumpWidget(HayyApp(authCubit: authCubit, dioClient: DioClient()));
    await tester.pump();
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    await authCubit.close();
  });
}
