import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/auth_model.dart';

class EmailVerificationFlowScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final bool isSignUp; // true for signup, false for login

  const EmailVerificationFlowScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    this.isSignUp = true,
  });

  @override
  State<EmailVerificationFlowScreen> createState() =>
      _EmailVerificationFlowScreenState();
}

class _EmailVerificationFlowScreenState
    extends State<EmailVerificationFlowScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;
  String? _errorMessage;
  late String _maskedEmail;

  @override
  void initState() {
    super.initState();
    _maskedEmail = _maskEmail(widget.email);
    // Start resend timer
    _startResendTimer();

    // Send initial OTP
    _sendInitialOTP();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _maskEmail(String email) {
    if (email.length <= 4) return email;
    int atIndex = email.indexOf('@');
    if (atIndex == -1) return email;

    String localPart = email.substring(0, atIndex);
    String domain = email.substring(atIndex);

    if (localPart.length <= 2) {
      return '${localPart[0]}***$domain';
    }

    return '${localPart[0]}***${localPart[localPart.length - 1]}$domain';
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer > 0) {
          _startResendTimer();
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  void _sendInitialOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use Firebase's built-in email verification
      final authModel = Provider.of<AuthModel>(context, listen: false);
      bool success = await authModel.sendFirebaseVerificationEmail(
          widget.email, widget.password, widget.name);

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success) {
        // Show success message instead of sending OTP
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Verification email sent to ${widget.email}. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to send verification email. Please check your email address.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _handleVerifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For Firebase verification, we check if the user's email is verified
      final authModel = Provider.of<AuthModel>(context, listen: false);
      bool result =
          await authModel.checkFirebaseEmailVerification(widget.email);

      if (mounted) {
        setState(() => _isLoading = false);

        if (result) {
          // Verification successful
          _showSuccessDialog();
        } else {
          // Verification failed
          setState(() {
            _errorMessage =
                'Email not verified yet. Please click the verification link in your email.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _handleResendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use Firebase's built-in email verification resend
      final authModel = Provider.of<AuthModel>(context, listen: false);
      bool success =
          await authModel.resendFirebaseVerificationEmail(widget.email);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });

        if (success) {
          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification email resent to $_maskedEmail'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage =
                'Failed to resend verification email. Please try again.';
          });
        }

        // Restart resend timer
        setState(() {
          _resendTimer = 30;
        });
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.green.shade50,
          title: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green.shade600, size: 28),
              const SizedBox(width: 12),
              Text(
                'Success!',
                style: GoogleFonts.inter(
                  color: Colors.green.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Your email has been successfully verified. You can now continue with your account.',
            style: GoogleFonts.inter(
              color: Colors.green.shade700,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                if (widget.isSignUp) {
                  // If this is signup, complete the signup process
                  _completeSignUp();
                } else {
                  // If this is login, return to login screen
                  Navigator.of(context)
                      .pop(true); // Return true to indicate success
                }
              },
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _completeSignUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // The account should already be created, so we just need to check verification
      final authModel = Provider.of<AuthModel>(context, listen: false);
      bool isVerified =
          await authModel.checkFirebaseEmailVerification(widget.email);

      if (isVerified) {
        // Email is verified, navigate to home screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Email is not yet verified. Please click the verification link.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _onOtpChanged(int index) {
    // Move to next field if current field is filled
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon:
                        const Icon(LucideIcons.arrowLeft, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                const SizedBox(height: 20),

                // Email verification icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.mailCheck,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Verify Your Email',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification link to $_maskedEmail',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Text(
                  'Please check your email inbox (and spam folder) and click the verification link.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Glassmorphism Card
                _buildGlassmorphismCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphismCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVerificationInstructions(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(_errorMessage!),
                  ],
                  const SizedBox(height: 30),
                  _buildVerifyButton(),
                  const SizedBox(height: 20),
                  _buildResendSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.info,
            color: Colors.blue.shade300,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'How to verify your email:',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '1. Check your email inbox\n2. Look for an email from Firebase\n3. Click the verification link in the email\n4. Return to the app to continue',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.red.shade200,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFF97316)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleVerifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'I Have Verified My Email',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        GestureDetector(
          onTap: _canResend ? _handleResendOTP : null,
          child: Text(
            _canResend ? 'Resend Code' : 'Resend in $_resendTimer s',
            style: GoogleFonts.inter(
              color: _canResend ? Colors.white : Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
