# Firebase Setup Guide for MindQuest App

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `mindquest-app` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Enable Authentication

1. In your Firebase project console, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" authentication
5. Click "Save"

## Step 3: Add Android App

1. In the Firebase console, click "Add app" and select Android
2. Enter your Android package name: `com.example.mindquest`
3. Enter app nickname: `MindQuest Android`
4. Download the `google-services.json` file
5. Place it in `android/app/` directory

## Step 4: Add iOS App (if needed)

1. Click "Add app" and select iOS
2. Enter your iOS bundle ID: `com.example.mindquest`
3. Enter app nickname: `MindQuest iOS`
4. Download the `GoogleService-Info.plist` file
5. Place it in `ios/Runner/` directory

## Step 5: Update Firebase Configuration

Replace the placeholder values in `firebase_options.dart` with your actual Firebase project configuration:

### Get your configuration values:

1. In Firebase Console, go to Project Settings (gear icon)
2. Scroll down to "Your apps" section
3. Click on your Android app
4. Copy the configuration values

### Update firebase_options.dart:

Replace these placeholder values with your actual values:

```dart
// For Android
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);

// For iOS (if you added iOS app)
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'your-actual-ios-api-key',
  appId: 'your-actual-ios-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
  iosBundleId: 'com.example.mindquest',
);
```

## Step 6: Test the Integration

1. Run your Flutter app: `flutter run`
2. Try creating a new account with your email: `abdelrahman.osama2430@gmail.com`
3. Try logging in with the created account

## Important Notes:

- Make sure to keep your Firebase configuration secure
- Never commit sensitive API keys to public repositories
- Test authentication on both Android and iOS devices
- The app will automatically handle user authentication state

## Troubleshooting:

If you encounter issues:
1. Make sure Firebase is properly initialized
2. Check that your package name matches Firebase configuration
3. Verify that Email/Password authentication is enabled
4. Check the console for any error messages

## Next Steps:

Once Firebase is set up, you can:
- Add user profiles to Firestore
- Implement password reset functionality
- Add social login (Google, Apple, etc.)
- Set up user data synchronization







