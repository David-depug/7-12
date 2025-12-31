import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/auth_model.dart';

class EmailVerificationWaitingScreen extends StatefulWidget {
  final String email;
  final String action; // 'signup' or 'login'

  const EmailVerificationWaitingScreen({
    super.key,
    required this.email,
    required this.action,
  });

  @override
  State<EmailVerificationWaitingScreen> createState() =>
      _EmailVerificationWaitingScreenState();
}

class _EmailVerificationWaitingScreenState
    extends State<EmailVerificationWaitingScreen> {
  bool _isCheckingVerification = false;
  bool _showResendButton = false;

  @override
  void initState() {
    super.initState();
    // Start checking verification status periodically
    _startVerificationCheck();

    // Show resend button after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showResendButton = true;
        });
      }
    });
  }

  void _startVerificationCheck() {
    // Check verification status every 5 seconds
    Future.delayed(const Duration(seconds: 5), _checkVerification);
  }

  void _checkVerification() async {
    if (!mounted) return;

    final authModel = Provider.of<AuthModel>(context, listen: false);

    try {
      bool isVerified =
          await authModel.checkEmailVerificationStatus(widget.email);

      if (mounted && isVerified) {
        // If verified, allow the user to proceed
        if (widget.action == 'signup') {
          // For signup, set the user as authenticated
          authModel.setAuthenticated(widget.email, widget.email.split('@')[0]);
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully. Account opened.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // For login, just show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Email verified successfully. You can now access the app.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        // Pop the waiting screen and return to login/signup
        Navigator.of(context).pop(); // Close this screen
        Navigator.of(context)
            .pop(); // Go back to previous screen (login/signup)
        return;
      }
    } catch (e) {
      print('Error checking verification: $e');
    }

    // Continue checking if not verified
    if (mounted) {
      _startVerificationCheck();
    }
  }

  void _resendVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final authModel = Provider.of<AuthModel>(context, listen: false);
      bool success = await authModel.resendVerificationEmailForCurrentUser();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email has been resent'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to resend verification email'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isCheckingVerification = false;
    });
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Verification Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
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
                  widget.action == 'signup'
                      ? 'Verification Email Sent'
                      : 'Email Verification Required',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  widget.action == 'signup'
                      ? 'Verification email sent. Please click the link to verify your account.'
                      : 'Please click the verification link sent to your email.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  widget.email,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // Status message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.refreshCw,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Checking verification status...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your inbox (and spam folder). Click the link in the email to verify your account.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Resend button
                if (_showResendButton)
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7C3AED),
                          Color(0xFFF97316),
                        ],
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
                      onPressed:
                          _isCheckingVerification ? null : _resendVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCheckingVerification
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Resend Verification Email',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Skip button for development
                TextButton(
                  onPressed: () {
                    // For development/testing purposes, you can skip verification
                    // In production, remove this button
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Skip for now (Dev)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
