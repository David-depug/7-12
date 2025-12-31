import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Note: For web platform, Firebase handles dynamic links automatically
// For mobile platforms, we would normally use firebase_dynamic_links
// but due to build issues, we'll handle email verification directly

class DynamicLinksService {
  static final DynamicLinksService _instance = DynamicLinksService._internal();
  factory DynamicLinksService() => _instance;
  DynamicLinksService._internal();

  /// Initialize dynamic links service - for web, Firebase handles this automatically
  /// For mobile, we'll provide a simplified version due to build issues with firebase_dynamic_links
  static Future<void> initDynamicLinks() async {
    debugPrint('Dynamic links service initialized');

    // On web, Firebase handles email verification links automatically
    // On mobile, we can handle them manually if they're passed as parameters
    if (kIsWeb) {
      debugPrint(
          'Web platform: Firebase handles email verification links automatically');
    } else {
      debugPrint('Mobile platform: Dynamic links require native setup');
    }
  }

  /// Check if a URL is an email verification link
  static bool isEmailVerificationLink(String? urlString) {
    if (urlString == null) return false;

    try {
      final Uri uri = Uri.parse(urlString);

      // Firebase email verification links contain 'mode' parameter with value 'verifyEmail'
      final String? mode = uri.queryParameters['mode'];
      final String? oobCode = uri.queryParameters['oobCode'];

      return mode == 'verifyEmail' && oobCode != null && oobCode.isNotEmpty;
    } catch (e) {
      debugPrint('Error parsing URL: \$e');
      return false;
    }
  }

  /// Handle email verification link
  static Future<bool> handleEmailVerificationLink(String? urlString) async {
    if (urlString == null) return false;

    try {
      final Uri uri = Uri.parse(urlString);

      // Check if this is an email verification link
      if (!isEmailVerificationLink(urlString)) {
        return false;
      }

      final String? oobCode = uri.queryParameters['oobCode'];

      if (oobCode != null && oobCode.isNotEmpty) {
        // Complete the email verification
        await FirebaseAuth.instance.applyActionCode(oobCode);

        // Check if the user is now verified
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            debugPrint('Email verification successful for: \${user.email}');
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling email verification link: \$e');
      return false;
    }

    return false;
  }

  /// Check if a URL is a password reset link
  static bool isPasswordResetLink(String? urlString) {
    if (urlString == null) return false;

    try {
      final Uri uri = Uri.parse(urlString);

      // Firebase password reset links contain 'mode' parameter with value 'resetPassword'
      final String? mode = uri.queryParameters['mode'];
      final String? oobCode = uri.queryParameters['oobCode'];

      return mode == 'resetPassword' && oobCode != null && oobCode.isNotEmpty;
    } catch (e) {
      debugPrint('Error parsing URL: \$e');
      return false;
    }
  }

  /// Handle password reset link
  static Future<bool> handlePasswordResetLink(String? urlString) async {
    if (urlString == null) return false;

    try {
      final Uri uri = Uri.parse(urlString);

      // Check if this is a password reset link
      if (!isPasswordResetLink(urlString)) {
        return false;
      }

      final String? oobCode = uri.queryParameters['oobCode'];

      if (oobCode != null && oobCode.isNotEmpty) {
        debugPrint('Password reset link received with code: \$oobCode');
        // The Firebase SDK will handle the password reset flow
        // This method returns true if it's a valid reset link
        return true;
      }
    } catch (e) {
      debugPrint('Error handling password reset link: \$e');
      return false;
    }

    return false;
  }
}
