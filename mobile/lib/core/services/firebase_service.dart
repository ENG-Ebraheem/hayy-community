import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initialize() async {
    // Note: Firebase.initializeApp() will use google-services.json (Android) 
    // or GoogleService-Info.plist (iOS) when configured via Firebase Console.
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Allows app initialization during early foundation testing if configuration file is pending
    }
  }
}
