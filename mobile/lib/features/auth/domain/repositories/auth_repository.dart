import 'package:firebase_auth/firebase_auth.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String email, String password);
  Future<void> logout();
}

String authMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم مسبقاً.';
      case 'weak-password':
        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
      case 'invalid-email':
        return 'أدخل بريداً إلكترونياً صحيحاً.';
      case 'network-request-failed':
        return 'تعذر الاتصال بخدمة المصادقة.';
      default:
        return 'تعذر إكمال عملية المصادقة.';
    }
  }
  return 'تعذر إكمال عملية المصادقة.';
}
