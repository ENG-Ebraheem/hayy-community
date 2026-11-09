import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final DateTime? createdAt;

  const Profile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    this.createdAt,
  });

  Profile copyWith({String? name, String? phone, String? bio}) => Profile(
        uid: uid,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [uid, name, email, phone, bio, createdAt];
}
