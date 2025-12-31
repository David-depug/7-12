# SHA Certificate Fingerprints Setup for Firebase

This document provides detailed instructions for generating and adding SHA-1 and SHA-256 certificate fingerprints to your Firebase project for Google Sign-In functionality.

## Why SHA Fingerprints are Required

SHA fingerprints are used by Google to authenticate your app and ensure that only your legitimate app can access Google services. They're required for:

- Google Sign-In
- Firebase Authentication
- Google APIs access

## Generate SHA Fingerprints

### For Windows (Debug Keystore)

Open Command Prompt or PowerShell and run:

```bash
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore
```

If prompted for a password, enter: `android`

### For macOS/Linux (Debug Keystore)

Open Terminal and run:

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
```

If prompted for a password, enter: `android`

### For Release Keystore

If you have a release keystore, run:

```bash
# Windows
keytool -list -v -keystore "C:\path\to\your\release\keystore.jks"

# macOS/Linux
keytool -list -v -keystore ~/path/to/your/release/keystore.jks
```

## Find Your SHA Fingerprints

After running the command, look for output similar to:

```
Certificate fingerprint:
         SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
         SHA256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy both the SHA-1 and SHA-256 fingerprints.

## Add SHA Fingerprints to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project "up-heal-0001"
3. Click on the gear icon (Project Settings)
4. Scroll down to the "Your apps" section
5. Find your Android app (package name: `com.example.mindquest` or similar)
6. Click on the Android package name to expand the settings
7. In the "SHA certificate fingerprints" section, click **Add fingerprint**
8. Paste your SHA-1 fingerprint and click **Add**
9. Repeat for SHA-256 fingerprint
10. Click **Save**

## Verify Your Setup

1. Make sure you've added both SHA-1 and SHA-256 fingerprints
2. If you have multiple keystores (debug, release, different developers), add all of them
3. The fingerprints are case-insensitive but must be entered exactly as shown

## Common Issues and Solutions

### Issue: "App not found" during Google Sign-In
- Verify that the package name in Firebase Console matches your app's package name
- Check that the SHA fingerprints match exactly

### Issue: Certificate fingerprint doesn't match
- Ensure you're using the correct keystore file
- Check for any extra spaces or characters when copying the fingerprint
- Try regenerating the fingerprint

### Issue: SHA-256 not available
- Some older keystores may not generate SHA-256 by default
- Use the `-v` flag to see all available fingerprints

## Package Name Verification

Make sure your app's package name matches what's registered in Firebase:

1. Check `android/app/build.gradle` for `applicationId`
2. This should match the package name in Firebase Console

## Testing

After adding the SHA fingerprints:

1. Run your Flutter app
2. Try the Google Sign-In button
3. The sign-in dialog should appear without authentication errors

## Additional Notes

- SHA fingerprints are only required for Android and iOS apps
- Web apps don't require SHA fingerprints
- You can have multiple SHA fingerprints for different build configurations
- Debug and release builds typically use different keystores, so both may need to be registered