import '../../domain/entities/profile.dart';
class ProfileModel extends Profile {
  const ProfileModel({required super.uid, required super.name, required super.email, required super.phone, required super.bio, super.createdAt});
  factory ProfileModel.fromEntity(Profile profile) => ProfileModel(uid: profile.uid, name: profile.name, email: profile.email, phone: profile.phone, bio: profile.bio, createdAt: profile.createdAt);
}
