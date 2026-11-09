import '../entities/profile.dart';
abstract class ProfileRepository {
  Future<Profile> getProfile(String uid, {String? email});
  Future<Profile> saveProfile(Profile profile);
}
