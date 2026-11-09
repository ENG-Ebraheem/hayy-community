import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({required super.uid, super.email, super.displayName});
  factory AppUserModel.fromFirebase(
          {required String uid, String? email, String? displayName}) =>
      AppUserModel(uid: uid, email: email, displayName: displayName);
}
