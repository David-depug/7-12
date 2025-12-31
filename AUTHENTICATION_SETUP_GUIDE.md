# Authentication System Setup Guide

This document provides a comprehensive guide to the authentication system implemented in the MindQuest app, including Google, Apple, Facebook, and email OTP sign-in methods.

## Overview

The authentication system includes:
- Google Sign-In with Firebase integration
- Apple Sign-In (iOS only) with Firebase integration  
- Facebook Sign-In with Firebase integration
- Email OTP verification system
- Phone authentication
- Traditional email/password authentication

## 1. Google Sign-In Setup

### Dependencies
- `google_sign_in: ^6.2.1`
- Firebase Authentication configured with Google provider

### Implementation
- Located in `lib/services/google_sign_in_service.dart`
- Integrated with `lib/models/auth_model.dart` via `signInWithGoogle()` method
- UI in `lib/screens/login_screen.dart` with dedicated Google button

### Firebase Configuration
1. Enable Google sign-in in Firebase Console Authentication section
2. Add SHA-1 and SHA-256 fingerprints to Firebase project settings
3. Configure OAuth in Google Cloud Console

## 2. Apple Sign-In Setup

### Dependencies
- `sign_in_with_apple: ^6.1.1`
- Firebase Authentication

### Implementation
- Implemented in `lib/screens/login_screen.dart` with `_handleAppleSignIn()` method
- Uses OAuth provider with Apple credentials
- Only functional on iOS devices

### iOS Configuration
1. Enable "Sign In with Apple" capability in Xcode
2. Configure associated domains
3. Add proper entitlements

## 3. Facebook Sign-In Setup

### Dependencies
- `flutter_facebook_auth: ^7.0.1`
- Firebase Authentication

### Implementation
- Implemented in `lib/screens/login_screen.dart` with `_handleFacebookSignIn()` method
- Uses Facebook Auth SDK with Firebase OAuth provider

### Facebook Configuration
1. Create Facebook App at https://developers.facebook.com/
2. Configure app for iOS and Android
3. Add package name and SHA-1 hash for Android
4. Configure app domain and redirect URLs

## 4. Email OTP Verification System

### Components
- `lib/services/custom_email_verification_service.dart` - Core OTP logic
- `lib/services/email_service.dart` - Email sending functionality
- `lib/screens/email_verification_flow_screen.dart` - OTP input UI

### Configuration
1. Set up SMTP in `lib/config.dart`:
   - `SMTP_USERNAME`: Your email address
   - `SMTP_PASSWORD`: App Password (not regular password)
   - `FROM_EMAIL`: Same as username
   - `FROM_NAME`: Display name for emails

### OTP Flow
1. User enters email during signup/login
2. System generates 6-digit OTP (valid for 5 minutes)
3. OTP stored in Firestore with expiration timestamp
4. OTP sent via email (or printed to console in development)
5. User enters OTP in verification screen
6. System validates OTP and marks email as verified

## 5. Resolved Issues

### Issue 1: Google Sign-In Error
**Problem**: "Login Failed: Please verify your email address before logging in" appeared during Google sign-in
**Solution**: Modified `signInWithGoogle()` method to automatically mark Google-verified emails as verified in Firestore

### Issue 2: Duplicate Social Buttons
**Problem**: Multiple identical Google buttons in UI
**Solution**: Implemented distinct buttons for Google, Apple, and Facebook with proper branding

### Issue 3: Mixed Authentication Flows
**Problem**: Gmail addresses used with Google Sign-In showing email verification prompts
**Solution**: Added logic to detect if email was previously used with Google Sign-In and show appropriate error message

### Issue 4: OTP Not Sent
**Problem**: OTP emails not being delivered
**Solution**: 
- Improved error handling in email service
- Added clear console output for development
- Enhanced validation for SMTP configuration
- Added fallback notifications

## 6. Security Considerations

- All passwords are salted with pepper encryption
- OTPs expire after 5 minutes
- Failed login attempts are tracked with account lockout
- OAuth credentials are handled securely
- Email verification prevents unauthorized access

## 7. Testing Instructions

### Google Sign-In
1. Ensure Firebase Google provider is enabled
2. Add proper SHA fingerprints
3. Test with real Google account

### Apple Sign-In (iOS only)
1. Ensure Sign In with Apple capability is enabled
2. Test on iOS device or simulator

### Facebook Sign-In
1. Configure Facebook app properly
2. Test with valid Facebook account

### Email OTP
1. Configure SMTP settings in config.dart
2. Test email sending and verification flow
3. Verify OTP expiration works correctly

## 8. Troubleshooting

### Common Issues:
- **"App not found" with Google**: Check SHA fingerprints in Firebase Console
- **"Sign In with Apple not working"**: Verify iOS configuration and capabilities
- **OTP not sent**: Verify SMTP configuration in config.dart
- **Email verification required**: Check Firebase Auth settings

### Development Mode:
- OTPs are printed to console when SMTP is not configured
- Use the printed OTP in the verification screen
- Configure proper SMTP for production deployment