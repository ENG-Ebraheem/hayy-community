import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;
  ProfileRepositoryImpl(this.remote);
  @override Future<Profile> getProfile(String uid, {String? email}) async { try { return await remote.getProfile(uid: uid, email: email); } catch (e) { throw mapDioFailure(e); } }
  @override Future<Profile> saveProfile(Profile profile) async { try { return await remote.saveProfile(profile); } catch (e) { throw mapDioFailure(e); } }
}
