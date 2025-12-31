// lib/services/google_sign_in_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Signs in with Google and authenticates with Firebase
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Use Firebase's built-in Google Sign-In with popup for web compatibility
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add additional scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Set custom parameters if needed
      googleProvider.setCustomParameters({
        // 'login_hint': 'user@example.com',
      });

      // Sign in with popup on web
      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Signs out from Firebase
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Checks if the user is currently signed in with Google
  static bool isSignedIn() {
    final User? currentUser = _auth.currentUser;
    return currentUser?.providerData
            .any((userInfo) => userInfo.providerId == 'google.com') ??
        false;
  }
}
