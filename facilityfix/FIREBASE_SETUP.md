# Firebase Setup Instructions

## Error: "FirebaseException is not a subtype of type JavaScriptObject"

This error occurs when Firebase is not properly configured for Flutter Web. Follow these steps to fix it:

## Solution Applied

### 1. ✅ Updated Dependencies
The `pubspec.yaml` has been updated with the correct Firebase dependencies:
```yaml
firebase_core: ^3.8.1
firebase_auth: ^5.3.3
firebase_auth_web: ^5.13.3
```

### 2. ✅ Created Firebase Configuration
A `firebase_options.dart` file has been created with placeholder values.

### 3. ✅ Initialized Firebase in main.dart
Firebase is now properly initialized before the app runs.

### 4. ✅ Fixed Exception Handling
All Firebase authentication code now properly catches `FirebaseAuthException` to avoid type errors on web.

## Next Steps: Configure Your Firebase Project

You need to replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase project credentials.

### Option 1: Use FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run the configuration command:
   ```bash
   flutterfire configure
   ```

3. Select your Firebase project and platforms
4. This will automatically generate `firebase_options.dart` with the correct values

### Option 2: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one)
3. Go to Project Settings (gear icon) > General
4. Scroll down to "Your apps"
5. Add a Web app if you haven't already
6. Copy the configuration values
7. Update `lib/firebase_options.dart` with your actual values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  appId: 'YOUR_APP_ID',
  measurementId: 'YOUR_MEASUREMENT_ID', // Optional
);
```

### Enable Authentication

1. In Firebase Console, go to Authentication > Sign-in method
2. Enable "Email/Password" provider
3. Save changes

## Testing the Fix

After configuring Firebase:

1. Install dependencies:
   ```bash
   cd frontend/facilityfix
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run -d chrome
   ```

3. Try to log in - you should no longer see the FirebaseException error

## Common Issues

### Issue: "Firebase: Error (auth/configuration-not-found)"
**Solution**: Make sure you've updated the Firebase configuration values in `firebase_options.dart`

### Issue: "Firebase: Error (auth/api-key-not-valid)"
**Solution**: Double-check your API key in Firebase Console and update `firebase_options.dart`

### Issue: Still seeing type errors
**Solution**: 
- Clear build cache: `flutter clean`
- Reinstall dependencies: `flutter pub get`
- Restart your IDE/editor

## Web-Specific Firebase Setup

For web deployments, you can also configure Firebase directly in `web/index.html`:

```html
<body>
  <!-- Firebase SDK -->
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
  
  <script>
    // Your web app's Firebase configuration
    const firebaseConfig = {
      apiKey: "YOUR_API_KEY",
      authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
      projectId: "YOUR_PROJECT_ID",
      storageBucket: "YOUR_PROJECT_ID.appspot.com",
      messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
      appId: "YOUR_APP_ID"
    };
    
    // Initialize Firebase
    firebase.initializeApp(firebaseConfig);
  </script>
  
  <script src="flutter_bootstrap.js" async></script>
</body>
```

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli)
