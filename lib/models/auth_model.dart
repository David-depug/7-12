// Complete rewrite of auth_model.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_auth_service.dart';
import '../utils/phone_formatter.dart';
import '../services/custom_email_verification_service.dart';
import '../services/google_sign_in_service.dart';

import '../services/cloudflare_service.dart';


const String PASSWORD_PEPPER = 'D9f#7kLp2@wVx8qZrT1mY!uB4sE0jHcN';

class AuthModel extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  String? _phoneNumber;
  final Map<String, int> _failedAttempts = {};
  final Map<String, UserProfile> _userProfiles =
      {}; // بيانات محلية للمزايا الإضافية
  String? _errorMessage; // ← تخزين آخر رسالة خطأ
  String? _verificationId; // For phone authentication

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get phoneNumber => _phoneNumber;
  String? get errorMessage => _errorMessage; // ← getter للاستخدام في UI

  AuthModel() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseAuthService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        _userName = user.displayName;
        _phoneNumber = user.phoneNumber;
        if (!_userProfiles.containsKey(user.email)) {
          _userProfiles[user.email!] = UserProfile(
            email: user.email!,
            name: user.displayName ?? '',
            salt: _generateSalt(),
            is2FAEnabled: true,
            activities: [],
          );
        }
      } else {
        _isAuthenticated = false;
        _userEmail = null;
        _userName = null;
        _phoneNumber = null;
      }
      notifyListeners();
    });
  }

  String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  String _generateOtp(String email, [int length = 6]) {
    final salt = _userProfiles[email]?.salt ?? _generateSalt();
    final rand = Random.secure();
    final otpBytes = List<int>.generate(length, (_) => rand.nextInt(10));
    final combined = utf8.encode(otpBytes.join() + salt + PASSWORD_PEPPER);
    final otpHash = base64Url.encode(combined);
    return otpHash.substring(0, length);
  }

  bool isValidEmail(String email) {
    // Basic email format validation
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&+*/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    // Check for disposable email domains
    final disposableDomains = {
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'trashmail.com',
      'disposablemail.net',
      'yopmail.com',
      'temp-mail.org',
      'getnada.com',
      'sharklasers.com',
      'grr.la',
      'guerrillamailblock.com',
      'guerrillamail.net',
      'guerrillamail.org',
      'guerrillamail.biz',
      'guerrillamail.de',
      'guerrillamail.info',
      'tempinbox.com',
      'temp-mail.com',
      'throwaway.email',
      'tempmail.com',
      'fakeinbox.com',
      'maildrop.cc',
      '10minutemail.net',
      '10minutesmail.com',
      'trashmail.net',
      'wegwerfmail.de',
      'tempmailaddress.com',
      'mailnesia.com',
      'dispostable.com',
      'yopmail.net',
      'tempail.com',
      'tempail.net',
      'tempmaildemo.com',
      'temp-mail.de',
      'sharklasers.com',
      'guerrillamail.com',
      'guerrillamailblock.com',
      'guerrillamail.net',
      'guerrillamail.org',
      'guerrillamail.biz',
      'guerrillamail.de',
      'guerrillamail.info',
    };

    final domain = email.split('@')[1].toLowerCase();
    return !disposableDomains.contains(domain);
  }

  String evaluatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\\$\%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score <= 1) return "Weak";
    if (score == 2) return "Medium";
    return "Strong";
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      // Validate email format and check for disposable emails
      if (!isValidEmail(email)) {
        _errorMessage =
            'Invalid email address. Please use a valid email address.';
        notifyListeners();
        return false;
      }

      final userCredential = await _firebaseAuthService
          .createUserWithEmailAndPassword(email, password);

      if (userCredential != null) {
        await _firebaseAuthService.updateUserProfile(displayName: name);

        // Send Firebase email verification after sign-up
        await _auth.currentUser!.sendEmailVerification();

        _userProfiles[email] = UserProfile(
          email: email,
          name: name,
          salt: _generateSalt(),
          is2FAEnabled: true,
          activities: ['Signed up'],
        );

        // Mark user as not authenticated until email is verified
        _isAuthenticated = false;
        _userEmail = email;
        _userName = name;
        _errorMessage =
            'Verification email sent. Please click the link in your email to continue.';
        notifyListeners();
        return false; // Return false to indicate user needs to verify email
      }

      _errorMessage = 'Failed to create account';
      return false;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'This email is already registered.';
      } else {
        String errorMessage = _getFirebaseAuthErrorMessage(e);
        _errorMessage = errorMessage;
      }
      notifyListeners();
      return false;
    } catch (e) {
      print('Signup error: $e');
      _errorMessage =
          'An unexpected error occurred during signup. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Mark user as verified in Firestore
  Future<void> _markUserAsVerified(String email) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'email': email,
        'emailVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update the user profile if it exists
      final user = _auth.currentUser;
      if (user != null && user.email == email) {
        await user.reload();
      }
    } catch (e) {
      print('Error marking user as verified: $e');
    }
  }

  /// Check if user's email is verified
  Future<bool> isEmailVerified(String email) async {
    try {
      // First check Firebase's built-in email verification (highest priority)
      final user = _auth.currentUser;
      if (user != null && user.email == email) {
        return user.emailVerified;
      }

      // For email verification check without being signed in, we need to rely on other methods
      // Since we can't check verification status without signing in, we'll try alternative approaches

      // Check if user has signed in before and their verification status was stored
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        // If we have the user in our collection, use that verification status
        if (userData?['emailVerified'] == true) {
          return true;
        }
      }

      // Fallback: Check our custom verification system
      bool isVerified =
          await CustomEmailVerificationService.isEmailVerified(email);
      if (isVerified) return true;

      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  /// Login with email verification check
  Future<bool?> loginWithVerificationCheck(
      String email, String password) async {
    try {
      final profile = _userProfiles[email];

      if (profile != null && profile.lockUntil != null) {
        final lockDate = DateTime.tryParse(profile.lockUntil!);
        if (lockDate != null && lockDate.isAfter(DateTime.now())) {
          _errorMessage = 'Account is temporarily locked. Try again later.';
          return false;
        }
      }

      final userCredential = await _firebaseAuthService
          .signInWithEmailAndPassword(email, password);

      // Check if email is verified before allowing login
      User? user = userCredential?.user;
      if (user != null) {
        bool isVerified = user.emailVerified;

        // Special handling for Gmail addresses that might have been used with Google Sign-In
        if (!isVerified) {
          // Check if the user exists in Firebase Auth (might have signed in with Google before)
          try {
            final userRecord = await _auth.fetchSignInMethodsForEmail(email);
            if (userRecord.isNotEmpty && userRecord.contains('google.com')) {
              // The user has previously signed in with Google, so they should use Google Sign-In
              _errorMessage =
                  'This email is associated with Google Sign-In. Please use Google to sign in.';
              return false;
            }
          } catch (e) {
            // If there's an error fetching sign-in methods, continue with verification check
            print('Error fetching sign-in methods: $e');
          }

          _errorMessage =
              'Your email address is not verified. Please check your email for verification instructions.';
          return false;
        }
      }

      if (userCredential != null) {
        _failedAttempts[email] = 0;
        profile?.lockUntil = null;
        profile?.lastLogin = DateTime.now().toIso8601String();
        profile?.activities.insert(
            0, '${DateTime.now().toIso8601String()} - Successful login');

        // Set user as authenticated since login was successful
        _isAuthenticated = true;
        _userEmail = email;
        _userName = profile?.name ?? '';
        _errorMessage = null;
        notifyListeners();

        return true; // Return true since user is authenticated after email verification
      }
      _errorMessage = 'Invalid email or password';
      return false;
    } catch (e) {
      print('Login error: $e');
      _errorMessage = e.toString();
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if (_failedAttempts[email]! >= 5) {
        final lockUntil = DateTime.now().add(const Duration(minutes: 10));
        _userProfiles[email]?.lockUntil = lockUntil.toIso8601String();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool?> login(String email, String password) async {
    try {
      final profile = _userProfiles[email];

      if (profile != null && profile.lockUntil != null) {
        final lockDate = DateTime.tryParse(profile.lockUntil!);
        if (lockDate != null && lockDate.isAfter(DateTime.now())) {
          _errorMessage = 'Account is temporarily locked. Try again later.';
          return false;
        }
      }

      final userCredential = await _firebaseAuthService
          .signInWithEmailAndPassword(email, password);

      // Check if email is verified before allowing login
      User? user = userCredential?.user;
      if (user != null) {
        // Always reload the user to get the latest verification status
        await user.reload();
        bool isVerified = user.emailVerified;

        if (!isVerified) {
          // Send verification email again since user is trying to login with unverified email
          await user.sendEmailVerification();
          _errorMessage =
              'Email verification required. A verification link has been sent to your email. Please click the link to verify your account.';
          return false;
        }

        // If user is verified, allow login
        if (isVerified && userCredential != null) {
          _failedAttempts[email] = 0;
          profile?.lockUntil = null;
          profile?.lastLogin = DateTime.now().toIso8601String();
          profile?.activities.insert(
              0, '${DateTime.now().toIso8601String()} - Successful login');

          // Set user as authenticated since login was successful
          _isAuthenticated = true;
          _userEmail = email;
          _userName = profile?.name ?? '';
          _errorMessage = null;
          notifyListeners();

          return true; // Return true since user is authenticated after email verification
        }
      }

      _errorMessage = 'Invalid email or password';
      return false;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        _errorMessage = 'No account found with this email address.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password. Please try again.';
      } else {
        String errorMessage = _getFirebaseAuthErrorMessage(e);
        _errorMessage = errorMessage;
      }
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if (_failedAttempts[email]! >= 5) {
        final lockUntil = DateTime.now().add(const Duration(minutes: 10));
        _userProfiles[email]?.lockUntil = lockUntil.toIso8601String();
      }
      notifyListeners();
      return false;
    } catch (e) {
      print('Login error: $e');
      _errorMessage =
          'An unexpected error occurred during login. Please try again.';
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if (_failedAttempts[email]! >= 5) {
        final lockUntil = DateTime.now().add(const Duration(minutes: 10));
        _userProfiles[email]?.lockUntil = lockUntil.toIso8601String();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final storedOtp = await _storage.read(key: 'otp_$email');
    if (storedOtp == otp) {
      final profile = _userProfiles[email];
      _isAuthenticated = true;
      _userEmail = email;
      _userName = profile?.name;
      await _storage.delete(key: 'otp_$email');
      profile?.activities.insert(0,
          '${DateTime.now().toIso8601String()} - 2FA verified, login complete');
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _userProfiles[email]?.activities.insert(
          0, '${DateTime.now().toIso8601String()} - Invalid OTP attempt');
      _errorMessage = 'Invalid OTP';
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuthService.signOut();

    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _phoneNumber = null;
    _errorMessage = null;

    // Clear stored OTPs and other sensitive data
    if (_userEmail != null) {
      await _storage.delete(key: 'otp_${_userEmail!}');
    }

    notifyListeners();
  }

  Future<void> toggle2FA(String email, bool enabled) async {
    final profile = _userProfiles[email];
    if (profile == null) return;
    profile.is2FAEnabled = enabled;
    profile.activities.insert(0,
        '${DateTime.now().toIso8601String()} - 2FA ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuthService.sendPasswordResetEmail(email);
    _userProfiles[email]?.activities.insert(
        0, '${DateTime.now().toIso8601String()} - Password reset requested');
  }

  /// Check if user's email is verified
  Future<bool> isUserEmailVerified(String email) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email == email) {
        return user.emailVerified;
      }

      // If user is not currently signed in, try to fetch user info
      final userRecord = await _auth.fetchSignInMethodsForEmail(email);
      // Note: We can't check verification status without signing in
      // This method will return false if user is not currently authenticated
      return false;
    } catch (e) {
      print('Error checking email verification status: $e');
      return false;
    }
  }

  /// Resend email verification to user
  Future<bool> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _userProfiles[user.email ?? '']?.activities.insert(0,
            '${DateTime.now().toIso8601String()} - Email verification resent');
        return true;
      }
      return false;
    } catch (e) {
      print('Error resending email verification: $e');
      return false;
    }
  }

  /// Send Firebase verification email during signup flow
  Future<bool> sendFirebaseVerificationEmail(
      String email, String password, String name) async {
    try {
      // Create the user account
      final userCredential = await _firebaseAuthService
          .createUserWithEmailAndPassword(email, password);

      if (userCredential != null) {
        await _firebaseAuthService.updateUserProfile(displayName: name);

        // Send Firebase email verification
        await _auth.currentUser!.sendEmailVerification();

        // Store user profile locally
        _userProfiles[email] = UserProfile(
            email: email,
            name: name,
            salt: _generateSalt(),
            is2FAEnabled: true,
            activities: ['Signed up - awaiting email verification']);

        return true;
      }
      return false;
    } catch (e) {
      print('Error sending Firebase verification email: $e');
      return false;
    }
  }

  /// Check if Firebase email verification is complete
  Future<bool> checkFirebaseEmailVerification(String email) async {
    try {
      // Reload user to get the latest email verification status
      final user = _auth.currentUser;
      if (user != null && user.email == email) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print('Error checking Firebase email verification: $e');
      return false;
    }
  }

  /// Resend Firebase verification email
  Future<bool> resendFirebaseVerificationEmail(String email) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email == email && !user.emailVerified) {
        await user.sendEmailVerification();
        _userProfiles[email]?.activities.insert(0,
            '${DateTime.now().toIso8601String()} - Firebase verification email resent');
        return true;
      }
      return false;
    } catch (e) {
      print('Error resending Firebase verification email: $e');
      return false;
    }
  }

  // Phone Authentication Methods

  /// Sends OTP to the provided phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      // Verify the phone number is in the correct format
      if (!phoneNumber.startsWith('+')) {
        throw Exception(
            'Phone number must be in international format (e.g. +20XXXXXXXXXX)');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval: Android only
          await _auth.signInWithCredential(credential);
          _isAuthenticated = true;
          final user = _auth.currentUser;
          if (user != null) {
            _userEmail = user.email;
            _userName = user.displayName;
            _phoneNumber = user.phoneNumber;
            if (!_userProfiles.containsKey(user.uid)) {
              _userProfiles[user.uid] = UserProfile(
                email: user.email ?? user.phoneNumber ?? user.uid,
                name: user.displayName ?? '',
                salt: _generateSalt(),
                is2FAEnabled: true,
                activities: [],
              );
            }
          }
          _errorMessage = null;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = 'Verification failed: ${e.message}';
          notifyListeners();
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Save verificationId for later use
          _verificationId = verificationId;
          _errorMessage = null;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timed out
          _errorMessage =
              'Auto-retrieval timed out. Please enter the code manually.';
          notifyListeners();
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _errorMessage = 'Failed to send OTP: $e';
      notifyListeners();
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verifies the OTP entered by the user
  Future<bool> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID found. Please request OTP first.');
      }

      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _isAuthenticated = true;
        final user = userCredential.user!;
        _userEmail = user.email;
        _userName = user.displayName;
        _phoneNumber = user.phoneNumber;
        if (!_userProfiles.containsKey(user.uid)) {
          _userProfiles[user.uid] = UserProfile(
            email: user.email ?? user.phoneNumber ?? user.uid,
            name: user.displayName ?? '',
            salt: _generateSalt(),
            is2FAEnabled: true,
            activities: [],
          );
        }
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to verify OTP. Please try again.';
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          _errorMessage = 'Invalid OTP code. Please check and try again.';
          break;
        case 'session-expired':
          _errorMessage = 'OTP session expired. Please request a new OTP.';
          break;
        default:
          _errorMessage = 'Failed to verify OTP: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error during OTP verification: $e';
      notifyListeners();
      return false;
    }
  }

  /// Resends the OTP to the same phone number
  Future<void> resendOTP(String phoneNumber) async {
    try {
      // Format the phone number if needed
      String formattedNumber = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // If not in international format, try to format as Egyptian number
        String? tempFormatted =
            PhoneNumberFormatter.formatEgyptianNumber(phoneNumber);
        if (tempFormatted != null) {
          formattedNumber = tempFormatted;
        } else {
          throw Exception('Invalid phone number format');
        }
      }
      await sendOTP(formattedNumber);
    } catch (e) {
      _errorMessage = 'Failed to resend OTP: $e';
      notifyListeners();
      throw Exception('Failed to resend OTP: $e');
    }
  }

  UserProfile? getUserProfile(String email) {
    return _userProfiles[email];
  }

  /// Google Sign-In method
  Future<bool> signInWithGoogle() async {
    try {
      _errorMessage = null;
      notifyListeners(); // Show loading state

      final userCredential = await GoogleSignInService.signInWithGoogle();

      if (userCredential?.user != null) {
        final user = userCredential!.user!;

        // Check if this is a new user or existing user
        if (!_userProfiles.containsKey(user.email)) {
          // Create a new profile for the Google user
          _userProfiles[user.email!] = UserProfile(
            email: user.email!,
            name: user.displayName ?? user.email!.split('@')[0],
            salt: _generateSalt(),
            is2FAEnabled: true,
            activities: ['Signed up with Google'],
          );
        }

        _isAuthenticated = true;
        _userEmail = user.email;
        _userName = user.displayName ?? user.email!.split('@')[0];
        _phoneNumber = user.phoneNumber;

        // Mark the user as verified in Firestore since Google already verified their email
        await _markUserAsVerified(user.email!);

        notifyListeners();
        return true;
      } else {
        // User cancelled the sign-in
        _errorMessage = 'Google Sign-In was cancelled';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      _errorMessage = 'Google Sign-In failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Enhanced signup with Cloudflare verification
  Future<bool> signUpWithCloudflare(String email, String password, String name,
      String cloudflareToken) async {
    try {
      // Verify Cloudflare token first
      bool isTokenValid = await verifyCloudflareToken(cloudflareToken);
      if (!isTokenValid) {
        _errorMessage = 'Security verification failed. Please try again.';
        notifyListeners();
        return false;
      }

      // Validate email format and check for disposable emails
      if (!isValidEmail(email)) {
        _errorMessage =
            'Invalid email address. Please use a valid email address.';
        notifyListeners();
        return false;
      }

      final userCredential = await _firebaseAuthService
          .createUserWithEmailAndPassword(email, password);
      if (userCredential != null) {
        await _firebaseAuthService.updateUserProfile(displayName: name);

        // Send Firebase email verification after sign-up
        await _auth.currentUser!.sendEmailVerification();

        _userProfiles[email] = UserProfile(
          email: email,
          name: name,
          salt: _generateSalt(),
          is2FAEnabled: true,
          activities: ['Signed up'],
        );

        // Mark user as not authenticated until email is verified
        _isAuthenticated = false;
        _userEmail = email;
        _userName = name;
        _errorMessage =
            'Please verify your email address. A verification email has been sent to your inbox.';
        notifyListeners();
        return false; // Return false to indicate user needs to verify email
      }
      _errorMessage = 'Failed to create account';
      return false;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'This account is already registered.';
      } else {
        String errorMessage = _getFirebaseAuthErrorMessage(e);
        _errorMessage = errorMessage;
      }
      notifyListeners();
      return false;
    } catch (e) {
      print('Signup error: $e');
      _errorMessage =
          'An unexpected error occurred during signup. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Enhanced login with Cloudflare verification
  Future<bool?> loginWithCloudflare(
      String email, String password, String cloudflareToken) async {
    try {
      // Verify Cloudflare token first
      bool isTokenValid = await verifyCloudflareToken(cloudflareToken);
      if (!isTokenValid) {
        _errorMessage = 'Security verification failed. Please try again.';
        notifyListeners();
        return false;
      }

      final profile = _userProfiles[email];

      if (profile != null && profile.lockUntil != null) {
        final lockDate = DateTime.tryParse(profile.lockUntil!);
        if (lockDate != null && lockDate.isAfter(DateTime.now())) {
          _errorMessage = 'Account is temporarily locked. Try again later.';
          return false;
        }
      }

      final userCredential = await _firebaseAuthService
          .signInWithEmailAndPassword(email, password);

      // Check if email is verified before allowing login
      User? user = userCredential?.user;
      if (user != null) {
        // Always reload the user to get the latest verification status
        await user.reload();
        bool isVerified = user.emailVerified;

        if (!isVerified) {
          // Send verification email again since user is trying to login with unverified email
          await user.sendEmailVerification();
          _errorMessage =
              'Email verification required. A verification link has been sent to your email. Please click the link to verify your account.';
          return false;
        }

        // If user is verified, allow login
        if (isVerified && userCredential != null) {
          _failedAttempts[email] = 0;
          profile?.lockUntil = null;
          profile?.lastLogin = DateTime.now().toIso8601String();
          profile?.activities.insert(
              0, '${DateTime.now().toIso8601String()} - Successful login');

          // Set user as authenticated since login was successful
          _isAuthenticated = true;
          _userEmail = email;
          _userName = profile?.name ?? '';
          _errorMessage = null;
          notifyListeners();

          return true; // Return true since user is authenticated after email verification
        }
      }

      _errorMessage = 'Invalid email or password';
      return false;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        _errorMessage = 'No account found with this email address.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password. Please try again.';
      } else {
        String errorMessage = _getFirebaseAuthErrorMessage(e);
        _errorMessage = errorMessage;
      }
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if (_failedAttempts[email]! >= 5) {
        final lockUntil = DateTime.now().add(const Duration(minutes: 10));
        _userProfiles[email]?.lockUntil = lockUntil.toIso8601String();
      }
      notifyListeners();
      return false;
    } catch (e) {
      print('Login error: $e');
      _errorMessage =
          'An unexpected error occurred during login. Please try again.';
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if (_failedAttempts[email]! >= 5) {
        final lockUntil = DateTime.now().add(const Duration(minutes: 10));
        _userProfiles[email]?.lockUntil = lockUntil.toIso8601String();
      }
      notifyListeners();
      return false;
    }
  }

  /// Enhanced Google Sign-In with Cloudflare verification
  Future<bool> signInWithGoogleWithCloudflare(String cloudflareToken) async {
    try {
      // Verify Cloudflare token first
      bool isTokenValid = await verifyCloudflareToken(cloudflareToken);
      if (!isTokenValid) {
        _errorMessage = 'Security verification failed. Please try again.';
        notifyListeners();
        return false;
      }

      _errorMessage = null;
      notifyListeners(); // Show loading state

      final userCredential = await GoogleSignInService.signInWithGoogle();

      if (userCredential?.user != null) {
        final user = userCredential!.user!;

        // Check if this is a new user or existing user
        if (!_userProfiles.containsKey(user.email)) {
          // Create a new profile for the Google user
          _userProfiles[user.email!] = UserProfile(
            email: user.email!,
            name: user.displayName ?? user.email!.split('@')[0],
            salt: _generateSalt(),
            is2FAEnabled: true,
            activities: ['Signed up with Google'],
          );
        }

        _isAuthenticated = true;
        _userEmail = user.email;
        _userName = user.displayName ?? user.email!.split('@')[0];
        _phoneNumber = user.phoneNumber;

        // Mark the user as verified in Firestore since Google already verified their email
        await _markUserAsVerified(user.email!);

        notifyListeners();
        return true;
      } else {
        // User cancelled the sign-in
        _errorMessage = 'Google Sign-In was cancelled';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      _errorMessage = 'Google Sign-In failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Verify Cloudflare token before proceeding with authentication
  Future<bool> verifyCloudflareToken(String token) async {
    try {
      bool isValid = await CloudflareService.verifyToken(token);
      return isValid;
    } catch (e) {
      print('Cloudflare verification error: $e');
      return false;
    }
  }

  /// Check if the current user signed in with Google
  bool isSignedInWithGoogle() {
    return GoogleSignInService.isSignedIn();
  }

  /// Check if current user's email is verified
  bool isCurrentUserEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Check email verification status for a specific email
  Future<bool> checkEmailVerificationStatus(String email) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email == email) {
        // Reload user to get the latest verification status
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print('Error checking email verification status: $e');
      return false;
    }
  }

  /// Resend verification email for the current user
  Future<bool> resendVerificationEmailForCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _userProfiles[user.email ?? '']?.activities.insert(0,
            '${DateTime.now().toIso8601String()} - Verification email resent');
        _errorMessage =
            'Verification email has been resent. Please check your inbox.';
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error resending verification email: $e');
      return false;
    }
  }

  /// Resend email verification to current user
  Future<bool> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _userProfiles[user.email ?? '']?.activities.insert(0,
            '${DateTime.now().toIso8601String()} - Verification email resent');
        return true;
      }
      return false;
    } catch (e) {
      print('Error resending verification email: $e');
      return false;
    }
  }

  /// Set authenticated status for a user
  void setAuthenticated(String email, String name) {
    _isAuthenticated = true;
    _userEmail = email;
    _userName = name;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error messages for Firebase authentication errors
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'An error occurred during login. Please try again.';
    }
  }
}

class UserProfile {
  final String email;
  String name;
  final String salt;
  bool is2FAEnabled;

  List<String> activities;
  String? lastLogin;
  String? lockUntil;

  UserProfile({
    required this.email,
    required this.name,
    required this.salt,
    required this.is2FAEnabled,
    required this.activities,
    this.lastLogin,
    this.lockUntil,
  });
}
