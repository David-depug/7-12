// lib/services/email_service.dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';

class EmailService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إرسال OTP للمستخدم عبر البريد
  static Future<void> sendOtp(String toEmail, String otp) async {
    try {
      // Always try to send via SMTP if configured
      if (SMTP_USERNAME.isNotEmpty &&
          SMTP_PASSWORD.isNotEmpty &&
          FROM_EMAIL.isNotEmpty) {
        final ok = await _sendEmailRaw(
          toEmail,
          'MindQuest OTP Verification',
          'Your OTP code is: $otp\n\nDo not share it with anyone.\nThis code expires in 5 minutes.',
        );

        if (ok) {
          print('OTP sent successfully to $toEmail');
          return;
        } else {
          print('Failed to send OTP via SMTP for $toEmail');
          print('Please check your email configuration in config.dart');
        }
      } else {
        print(
            'SMTP not configured. Please set up your email settings in config.dart');
        print('Email: $toEmail, OTP: [HIDDEN FOR SECURITY]');
      }

      // For production, consider implementing alternative delivery methods
      // like Firebase Cloud Messaging or SMS as fallbacks
    } catch (e) {
      print('Failed to send OTP: $e');
      // Log error for debugging purposes
    }
  }

  /// إرسال طلب إعادة تعيين كلمة المرور
  static Future<void> sendPasswordResetRequest(String toEmail) async {
    try {
      if (SMTP_USERNAME.isNotEmpty &&
          SMTP_PASSWORD.isNotEmpty &&
          FROM_EMAIL.isNotEmpty) {
        final ok = await _sendEmailRaw(
          toEmail,
          'MindQuest Password Reset',
          'We received a request to reset your password.\n'
              'If this was you, please follow the instructions in the app.\n'
              'If not, ignore this message.',
        );
        if (ok) return;
      }

      // 🔹 إذا لم يتم تكوين SMTP أو فشل، نرسل عبر Firebase Auth
      await _auth.sendPasswordResetEmail(email: toEmail);

      if (kDebugMode) print('Password reset email sent to $toEmail');
    } catch (e) {
      if (kDebugMode) print('Failed to send password reset email: $e');
    }
  }

  /// دالة مساعدة لإرسال البريد عبر SMTP
  static Future<bool> _sendEmailRaw(
      String toEmail, String subject, String body) async {
    if (SMTP_USERNAME.isEmpty || SMTP_PASSWORD.isEmpty || FROM_EMAIL.isEmpty) {
      if (kDebugMode) {
        print('*** SMTP not configured. Email not sent to $toEmail ***');
      }
      return false;
    }

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
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      if (kDebugMode) print('Email sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      if (kDebugMode) print('MailerException: ${e.toString()}');
      for (var p in e.problems) {
        if (kDebugMode) print(' - problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Unexpected email error: $e');
      return false;
    }
  }
}
