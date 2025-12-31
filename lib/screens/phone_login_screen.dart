import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/auth_model.dart';
import 'phone_verification_screen.dart';
import '../utils/phone_formatter.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Format the phone number to international format
        String? formattedNumber =
            PhoneNumberFormatter.formatEgyptianNumber(_phoneController.text);

        if (formattedNumber == null) {
          throw Exception(
              'Invalid Egyptian phone number format. Please enter a valid number like 01XXXXXXXXX');
        }

        final authModel = Provider.of<AuthModel>(context, listen: false);
        await authModel.sendOTP(formattedNumber);

        if (mounted) {
          setState(() => _isLoading = false);

          // Navigate to verification screen with the formatted number
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhoneVerificationScreen(
                phoneNumber: formattedNumber,
              ),
            ),
          );
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

                // 3D Character Illustration
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
                    LucideIcons.phone,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // Welcome Text
                Text(
                  'Phone Authentication',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your phone number to receive an OTP',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
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
                  _buildPhoneField(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(_errorMessage!),
                  ],
                  const SizedBox(height: 30),
                  _buildSendOTPButton(),
                  const SizedBox(height: 20),
                  _buildTermsText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
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
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: 'Phone Number',
          hintText: '+1 234 567 8900',
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          labelStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            LucideIcons.phone,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.purple.withOpacity(0.5),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          // Simple phone number validation
          if (value.length < 10) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
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

  Widget _buildSendOTPButton() {
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
        onPressed: _isLoading ? null : _handleSendOTP,
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
                'Send OTP',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: GoogleFonts.inter(
        color: Colors.white.withOpacity(0.6),
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }
}
