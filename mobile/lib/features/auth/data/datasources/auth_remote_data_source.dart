import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';

class AuthRemoteDataSource {
  final FirebaseAuth? firebaseAuth;

  AuthRemoteDataSource({FirebaseAuth? firebaseAuth})
      : firebaseAuth = firebaseAuth ?? _tryFirebaseAuth();

  Stream<AppUser?> authStateChanges() { 
    final auth = firebaseAuth;
    return auth == null
        ? Stream<AppUser?>.value(null)
        : auth.authStateChanges().map(_mapUser);
  }

  Future<AppUser> login(String email, String password) async {
    final auth = _requiredAuth();
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requiredUser(credential.user);
  }

  Future<AppUser> register(String email, String password) async {
    final auth = _requiredAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requiredUser(credential.user);
  }

  Future<void> logout() async {
    await firebaseAuth?.signOut();
  }

  FirebaseAuth _requiredAuth() {
    final auth = firebaseAuth;
    if (auth == null) {
      throw FirebaseAuthException(code: 'configuration-not-found');
    }
    return auth;
  }

  AppUser? _mapUser(User? user) => user == null
      ? null
      : AppUser(uid: user.uid, email: user.email, displayName: user.displayName);

  AppUser _requiredUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) throw FirebaseAuthException(code: 'user-not-found');
    return mapped;
  }

  static FirebaseAuth? _tryFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }
}
