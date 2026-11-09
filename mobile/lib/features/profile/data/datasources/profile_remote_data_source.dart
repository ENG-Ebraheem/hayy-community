import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore? firestore;
  ProfileRemoteDataSource({FirebaseFirestore? firestore})
      : firestore = firestore ?? _tryFirestore();

  Future<Profile> getProfile({required String uid, String? email}) async {
    final ref = firestore?.collection('users').doc(uid);
    final snapshot = ref == null ? null : await ref.get();
    final data = snapshot?.data() ?? <String, dynamic>{};
    return Profile(
      uid: uid,
      name: '${data['name'] ?? ''}',
      email: '${data['email'] ?? email ?? ''}',
      phone: '${data['phone'] ?? ''}',
      bio: '${data['bio'] ?? ''}',
      createdAt: _date(data['createdAt']),
    );
  }

  Future<Profile> saveProfile(Profile profile) async {
    final ref = firestore?.collection('users').doc(profile.uid);
    if (ref == null) return profile;
    await ref.set({
      'name': profile.name,
      'email': profile.email,
      'phone': profile.phone,
      'bio': profile.bio,
      'createdAt': profile.createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(profile.createdAt!),
    }, SetOptions(merge: true));
    return profile;
  }

  static FirebaseFirestore? _tryFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return value == null ? null : DateTime.tryParse('$value');
  }
}
