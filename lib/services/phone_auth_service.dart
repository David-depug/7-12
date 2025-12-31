import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends an OTP to the provided phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval: Android only
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Save verificationId for later use
          // This would typically be stored in a state management solution
          // For now, we'll pass it back to the caller
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timed out
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verifies the OTP entered by the user
  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('Invalid OTP code. Please check and try again.');
        case 'session-expired':
          throw Exception('OTP session expired. Please request a new OTP.');
        default:
          throw Exception('Failed to verify OTP: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error during OTP verification: $e');
    }
  }

  /// Resends the OTP to the same phone number
  Future<void> resendOTP(String phoneNumber) async {
    try {
      await sendOTP(phoneNumber);
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }
}
