# Google Sign-In Setup for MindQuest App

This document provides step-by-step instructions to set up Google Sign-In for your Flutter app with Firebase Authentication.

## Prerequisites

1. A Firebase project (already exists as "up-heal-0001")
2. Google Services files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)

## Step 1: Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project "up-heal-0001"
3. Navigate to **Authentication** > **Sign-in method** tab
4. Click on **Google** provider
5. Enable the toggle switch
6. Add your project's domain (or leave as default for development)
7. Click **Save**

## Step 2: Android Configuration

### Get SHA-1 and SHA-256 Fingerprints

For debug builds:
```bash
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore
```

For release builds (if you have a release keystore):
```bash
keytool -list -v -keystore /path/to/your/release/keystore.jks
```

### Add SHA Fingerprints to Firebase Console

1. In Firebase Console, go to your project settings (gear icon)
2. Scroll down to "Your apps" section
3. Find your Android app and click on the package name
4. Add the SHA-1 and SHA-256 fingerprints under "SHA certificate fingerprints"
5. Click **Save**

## Step 3: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (should match your Firebase project)
3. Navigate to **APIs & Services** > **Credentials**
4. If no OAuth 2.0 Client ID exists, click **Create Credentials** > **OAuth 2.0 Client ID**
5. For application type, select **Android** 
6. Enter:
   - Package name: `com.example.mindquest` (or your actual package name)
   - SHA-1 certificate fingerprint: [your SHA-1 fingerprint]
7. Click **Create**

## Step 4: Android-specific Configuration

### Update `android/app/build.gradle`

Make sure your app's `build.gradle` includes the classpath for Google Services:

```gradle
dependencies {
    // Other dependencies...
    classpath 'com.google.gms:google-services:4.4.0' // Or latest version
}
```

### Update `android/app/src/main/AndroidManifest.xml`

Add the following permission if not already present:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Update `android/build.gradle` (project level)

Make sure you have Google Services plugin applied:
```gradle
plugins {
    id 'com.google.gms.google-services' version '4.4.0' apply false
    // other plugins...
}
```

## Step 5: iOS Configuration (if needed)

1. In Firebase Console project settings, add your iOS app with bundle ID
2. Download `GoogleService-Info.plist` and add to iOS project
3. In Google Cloud Console, create iOS OAuth 2.0 Client ID with bundle ID

## Step 6: Testing

1. Make sure you've run `flutter pub get` to install `google_sign_in` dependency
2. Test the sign-in flow in your app
3. If using Android, ensure you're testing on a device with Google Play Services

## Troubleshooting

### Common Issues:

1. **"App not found in Firebase" error**: Check that SHA fingerprints match exactly
2. **"OAuth not configured" error**: Verify OAuth 2.0 Client ID is created in Google Cloud Console
3. **"Sign-in cancelled"**: Make sure the app is properly configured and running on a device with Google Play Services

### For Development:

- If you're testing on an emulator, make sure it has Google Play Services installed
- For physical devices, ensure Google Play Services are updated

## Important Notes

- The Google Sign-In will work with your existing Firebase Authentication system
- Users who sign in with Google will be stored in your existing user system
- The email verification system will work alongside Google Sign-In (Google-verified emails are automatically marked as verified)
- Remember to handle the case where users might sign in with Google but also have email/password accounts with the same email

## Security Considerations

- Store OAuth client secrets securely (they're already handled by Firebase)
- Verify user identity on your backend if needed
- Implement proper user data handling for Google sign-in users