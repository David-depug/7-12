import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config.dart';

class CustomEmailVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a random 6-digit OTP
  static String _generateOTP() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  /// Send OTP to email for verification
  static Future<String?> sendVerificationOTP(String email) async {
    try {
      String otp = _generateOTP();

      // Store OTP in Firestore with expiration time (5 minutes)
      await _firestore.collection('email_verifications').doc(email).set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
        'verified': false,
      });

      // Try to send via SMTP if configured
      if (SMTP_USERNAME.isNotEmpty &&
          SMTP_PASSWORD.isNotEmpty &&
          FROM_EMAIL.isNotEmpty) {
        bool success = await _sendEmailOTP(email, otp);
        if (success) {
          print('Verification OTP sent successfully to $email');
          return otp;
        } else {
          print('Failed to send OTP via SMTP, using fallback for $email');
        }
      }

      // If SMTP is not configured, we cannot send the OTP email
      // In production, you might want to implement alternative delivery methods
      // like Firebase Cloud Messaging, SMS, or other notification services
      print('SMTP not configured. OTP email could not be sent to $email');

      // For development, return null to indicate failure rather than printing OTP
      return null;

      // For production, consider implementing alternative delivery methods
      // like Firebase Cloud Messaging or SMS as fallbacks

      return otp;
    } catch (e) {
      print('Error sending verification OTP: $e');
      return null;
    }
  }

  /// Verify OTP entered by user during signup/login
  static Future<bool> verifyOTP(String email, String otp) async {
    try {
      DocumentSnapshot otpDoc =
          await _firestore.collection('email_verifications').doc(email).get();

      if (!otpDoc.exists) {
        print('No verification OTP found for email: $email');
        return false;
      }

      Map<String, dynamic> data = otpDoc.data() as Map<String, dynamic>;
      String storedOTP = data['otp'];
      Timestamp? expiresAt = data['expiresAt'];
      bool? isVerified = data['verified'];

      // Check if OTP has expired
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        // Delete expired OTP
        await _firestore.collection('email_verifications').doc(email).delete();
        print('Verification OTP has expired for email: $email');
        return false;
      }

      // Check if already verified
      if (isVerified == true) {
        print('Email already verified: $email');
        return true;
      }

      // Verify OTP
      bool isValid = storedOTP == otp;

      if (isValid) {
        // Update verification status
        await _firestore.collection('email_verifications').doc(email).update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        print('Email verified successfully: $email');

        // Also update user profile in Firestore if user exists
        await _updateUserVerificationStatus(email);
      } else {
        print('Invalid verification OTP for email: $email');
      }

      return isValid;
    } catch (e) {
      print('Error verifying email OTP: $e');
      return false;
    }
  }

  /// Check if user's email is verified
  static Future<bool> isEmailVerified(String email) async {
    try {
      DocumentSnapshot otpDoc =
          await _firestore.collection('email_verifications').doc(email).get();

      if (!otpDoc.exists) {
        return false;
      }

      Map<String, dynamic> data = otpDoc.data() as Map<String, dynamic>;
      bool? isVerified = data['verified'];

      return isVerified == true;
    } catch (e) {
      print('Error checking email verification status: $e');
      return false;
    }
  }

  /// Update user verification status in user profile
  static Future<void> _updateUserVerificationStatus(String email) async {
    try {
      // Find user document by email
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentReference userDoc = userQuery.docs.first.reference;
        await userDoc.update({'emailVerified': true});
      }
    } catch (e) {
      print('Error updating user verification status: $e');
    }
  }

  /// Send OTP via email using SMTP
  static Future<bool> _sendEmailOTP(String toEmail, String otp) async {
    final smtpServer = SmtpServer(
      SMTP_HOST,
      port: SMTP_PORT,
      username: SMTP_USERNAME,
      password: SMTP_PASSWORD,
      ssl: SMTP_PORT == 465,
      ignoreBadCertificate: true,
    );

    final message = Message()
      ..from = const Address(FROM_EMAIL, FROM_NAME)
      ..recipients.add(toEmail)
      ..subject = 'MindQuest - Email Verification Code'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #7C3AED;">Email Verification Required</h2>
          <p>Your verification code is:</p>
          <div style="font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background: #f0f0f0; border-radius: 10px; margin: 20px 0;">
            $otp
          </div>
          <p>This code will expire in 5 minutes.</p>
          <p>Please enter this code in the MindQuest app to verify your email address.</p>
          <p>If you didn't request this, please ignore this email.</p>
          <hr>
          <p style="font-size: 12px; color: #666;">MindQuest Security Team</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Verification OTP sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('MailerException: ${e.toString()}');
      for (var p in e.problems) {
        print(' - problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('Unexpected email error: $e');
      return false;
    }
  }

  /// Resend OTP to email
  static Future<String?> resendOTP(String email) async {
    // Delete existing OTP if it exists
    await _firestore.collection('email_verifications').doc(email).delete();
    // Send new OTP
    return await sendVerificationOTP(email);
  }
}
