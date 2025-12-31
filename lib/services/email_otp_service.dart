import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config.dart';

class EmailOTPService {
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

  /// Send OTP to email using SMTP or fallback to console
  static Future<String?> sendOTP(String email) async {
    try {
      String otp = _generateOTP();

      // Store OTP in Firestore with expiration time (5 minutes)
      await _firestore.collection('email_otps').doc(email).set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
      });

      // Try to send via SMTP if configured
      if (SMTP_USERNAME.isNotEmpty && SMTP_PASSWORD.isNotEmpty) {
        bool success = await _sendEmailOTP(email, otp);
        if (success) {
          return otp;
        }
      }

      // If SMTP is not configured, we cannot send the OTP email
      // In production, implement proper alternative delivery methods
      print('SMTP not configured. OTP email could not be sent to $email');
      return null;
    } catch (e) {
      print('Error sending email OTP: $e');
      return null;
    }
  }

  /// Verify OTP entered by user
  static Future<bool> verifyOTP(String email, String otp) async {
    try {
      DocumentSnapshot otpDoc =
          await _firestore.collection('email_otps').doc(email).get();

      if (!otpDoc.exists) {
        print('No OTP found for email: $email');
        return false;
      }

      Map<String, dynamic> data = otpDoc.data() as Map<String, dynamic>;
      String storedOTP = data['otp'];
      Timestamp? expiresAt = data['expiresAt'];

      // Check if OTP has expired
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        // Delete expired OTP
        await _firestore.collection('email_otps').doc(email).delete();
        print('OTP has expired for email: $email');
        return false;
      }

      // Verify OTP
      bool isValid = storedOTP == otp;

      if (isValid) {
        // Delete OTP after successful verification
        await _firestore.collection('email_otps').doc(email).delete();
        print('OTP verified successfully for email: $email');
      } else {
        print('Invalid OTP for email: $email');
      }

      return isValid;
    } catch (e) {
      print('Error verifying email OTP: $e');
      return false;
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
          <h2 style="color: #7C3AED;">Email Verification</h2>
          <p>Your verification code is:</p>
          <div style="font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background: #f0f0f0; border-radius: 10px; margin: 20px 0;">
            $otp
          </div>
          <p>This code will expire in 5 minutes.</p>
          <p>If you didn't request this, please ignore this email.</p>
          <hr>
          <p style="font-size: 12px; color: #666;">MindQuest Security Team</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email OTP sent: $sendReport');
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
    await _firestore.collection('email_otps').doc(email).delete();
    // Send new OTP
    return await sendOTP(email);
  }
}
