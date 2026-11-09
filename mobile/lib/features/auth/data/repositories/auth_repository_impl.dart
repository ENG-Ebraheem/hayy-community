import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  AuthRepositoryImpl(this.remote);

  @override
  Stream<AppUser?> authStateChanges() => remote.authStateChanges();

  @override
  Future<AppUser> login(String email, String password) async {
    try {
      return await remote.login(email, password);
    } catch (error) {
      throw AuthFailure(authMessage(error));
    }
  }

  @override
  Future<AppUser> register(String email, String password) async {
    try {
      return await remote.register(email, password);
    } catch (error) {
      throw AuthFailure(authMessage(error));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remote.logout();
    } catch (error) {
      throw AuthFailure(authMessage(error));
    }
  }
}
