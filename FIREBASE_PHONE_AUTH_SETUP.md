# Firebase Phone Authentication Setup Guide

This guide explains how to enable phone authentication in your Firebase project for the MindQuest app.

## Prerequisites

1. Ensure you have a Firebase project set up
2. Have the Firebase CLI installed
3. Your Flutter project already configured with Firebase

## Step 1: Enable Phone Authentication in Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** > **Sign-in method** tab
4. Click on **Phone** under "Sign-in providers"
5. Toggle the **Enable** switch to ON
6. Click **Save**

## Step 2: Configure SHA-1 and SHA-256 Certificates (Android)

For Android, you need to add your app's SHA-1 and SHA-256 certificates to Firebase:

### For Debug Certificate:
```bash
# Windows
keytool -list -v -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore"

# macOS/Linux
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
```

### For Release Certificate:
```bash
keytool -list -v -keystore /path/to/your/release/key.jks -alias your_key_alias
```

### Add Certificates to Firebase:
1. In Firebase Console, go to Project Settings
2. Scroll down to "Your apps" section
3. Select your Android app
4. Add the SHA-1 and SHA-256 certificate fingerprints

## Step 3: Update Dependencies

Ensure you have the latest Firebase Authentication dependency in your `pubspec.yaml`:

```yaml
dependencies:
  firebase_auth: ^6.1.2
```

Run `flutter pub get` to install the dependencies.

## Step 4: Re-download google-services.json

After enabling phone authentication, re-download the `google-services.json` file:

1. In Firebase Console, go to Project Settings
2. Scroll down to "Your apps" section
3. Download the updated `google-services.json` file
4. Replace the existing file in `android/app/` directory

## Step 5: Android Additional Configuration

### Update AndroidManifest.xml

In `android/app/src/main/AndroidManifest.xml`, add the following inside the `<application>` tag:

```xml
<meta-data
    android:name="firebase_auth_phone_enabled"
    android:value="true" />
```

### Update build.gradle

In `android/app/build.gradle`, ensure you have the latest Firebase BoM:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-auth'
}
```

## Step 6: iOS Additional Configuration

### Enable Push Notifications

Phone authentication on iOS requires push notifications to be enabled:

1. In Xcode, select your project target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Push Notifications**

### Enable Background Modes

1. In Xcode, select your project target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Background Modes**
5. Check **Remote notifications**

## Common Issues and Solutions

### Issue 1: "This app is not authorized to use Firebase Authentication"

**Solution:** 
- Ensure SHA-1 and SHA-256 certificates are added to Firebase
- Re-download and replace `google-services.json`
- Check that the package name matches exactly

### Issue 2: "The SMS code has expired"

**Solution:**
- The default timeout is 60 seconds
- Implement a resend mechanism in your app
- Test with a real phone number (test numbers in Firebase console won't expire)

### Issue 3: "Missing client type"

**Solution:**
- Ensure both Android and iOS apps are registered in Firebase if supporting both platforms
- Check that the correct `google-services.json` and `GoogleService-Info.plist` files are in place

### Issue 4: "TOO_MANY_REQUESTS"

**Solution:**
- This happens when too many OTP requests are sent
- Implement rate limiting in your app
- Use test phone numbers in Firebase Console for development

## Testing Phone Authentication

### Using Test Phone Numbers

Firebase allows you to create test phone numbers for development:

1. In Firebase Console, go to Authentication > Sign-in method
2. Scroll to "Phone" provider
3. Expand "Test phone numbers"
4. Add a test phone number and verification code

### Example Test Data:
- Phone Number: +1 555-555-5555
- Verification Code: 123456

## Security Best Practices

1. **Rate Limiting**: Implement rate limiting to prevent abuse
2. **Session Management**: Properly handle user sessions
3. **Data Validation**: Validate phone numbers on both client and server
4. **Secure Storage**: Store sensitive data securely using Flutter Secure Storage
5. **Timeout Handling**: Implement proper timeout handling for OTP codes

## Troubleshooting Tips

1. **Check Firebase Logs**: Use `firebase log` to see detailed error messages
2. **Verify Network Connectivity**: Ensure the device has internet access
3. **Test with Real Devices**: Emulators may not support SMS properly
4. **Check Country Codes**: Ensure phone numbers include correct country codes
5. **Review Firebase Rules**: Make sure Firestore/Realtime Database rules allow authenticated access

## Production Considerations

1. **Costs**: Be aware of SMS costs for phone authentication
2. **Quotas**: Monitor Firebase Authentication quotas
3. **Fallback Options**: Provide alternative authentication methods
4. **User Experience**: Design clear error messages and instructions
5. **Compliance**: Ensure compliance with privacy regulations (GDPR, CCPA, etc.)

By following this guide, you should have successfully enabled phone authentication in your MindQuest app. Remember to thoroughly test the implementation before deploying to production.