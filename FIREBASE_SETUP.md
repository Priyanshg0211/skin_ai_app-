# Firebase Setup Guide for SAGAlyze

This guide will help you set up Firebase for the SAGAlyze application.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Android Studio / Xcode (for platform-specific setup)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project" or select an existing project
3. Enter project name: `SAGAlyze` (or your preferred name)
4. Follow the setup wizard:
   - Enable Google Analytics (optional but recommended)
   - Accept terms and create project

## Step 2: Add Android App

1. In Firebase Console, click the Android icon (or "Add app" > Android)
2. Register your app:
   - **Package name**: Check your `android/app/build.gradle` file for `applicationId`
   - **App nickname**: SAGAlyze Android (optional)
   - **Debug signing certificate**: Optional for now
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. Update `android/build.gradle`:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```
6. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## Step 3: Add iOS App (if needed)

1. In Firebase Console, click the iOS icon
2. Register your app:
   - **Bundle ID**: Check your `ios/Runner.xcodeproj` for Bundle Identifier
   - **App nickname**: SAGAlyze iOS (optional)
3. Download `GoogleService-Info.plist`
4. Open Xcode and add it to `ios/Runner/` directory
5. Ensure it's added to the Xcode project

## Step 4: Enable Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable **Email/Password** provider:
   - Click on "Email/Password"
   - Toggle "Enable"
   - Click "Save"

## Step 5: Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Choose **Start in test mode** (for development)
4. Select your preferred location
5. Click "Enable"

### Firestore Security Rules (Update after testing)

Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'clinician'];
    }
    
    // Patients collection
    match /patients/{patientId} {
      // Patients can only read their own record
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'clinician', 'receptionist']);
      
      // Only clinicians, admins, and receptionists can write
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'clinician', 'receptionist'];
      
      // Visits subcollection
      match /visits/{visitId} {
        allow read: if request.auth != null && 
          (get(/databases/$(database)/documents/patients/$(patientId)).data.userId == request.auth.uid || 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'clinician', 'receptionist']);
        
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'clinician'];
      }
    }
  }
}
```

## Step 6: Set Up Firebase Storage

1. In Firebase Console, go to **Storage**
2. Click "Get started"
3. Start in **test mode** (for development)
4. Select your preferred location
5. Click "Done"

### Storage Security Rules (Update after testing)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /patients/{patientId}/visits/{visitId} {
      // Only authenticated users with proper roles can access
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role in ['admin', 'clinician'];
    }
  }
}
```

## Step 7: Install Dependencies

Run in your project root:

```bash
flutter pub get
```

## Step 8: Initialize Firebase in Your App

The Firebase initialization is already added in `lib/main.dart`. Make sure your Firebase project is properly configured.

## Step 9: Test the Setup

1. Run the app: `flutter run`
2. The app should show the role selection screen
3. Try creating accounts for different roles:
   - Admin
   - Clinician
   - Patient
   - Receptionist

## Account Types

The app supports 4 different account types:

1. **Admin**: Full system access and management
2. **Clinician**: Access to patient records and analysis tools
3. **Patient**: View own medical records
4. **Receptionist**: Patient registration and scheduling

## Troubleshooting

### Android Issues

- **Error: "Default FirebaseApp is not initialized"**
  - Ensure `google-services.json` is in `android/app/`
  - Check that `apply plugin: 'com.google.gms.google-services'` is in `android/app/build.gradle`

### iOS Issues

- **Error: "FirebaseApp.configure()" not called**
  - Ensure `GoogleService-Info.plist` is added to Xcode project
  - Check that it's included in the target

### General Issues

- **Authentication not working**
  - Verify Email/Password is enabled in Firebase Console
  - Check Firestore security rules allow user creation

- **Data not saving**
  - Check Firestore security rules
  - Verify network connectivity
  - Check Firebase Console for error logs

## Next Steps

1. Set up proper security rules for production
2. Enable additional authentication methods (Google Sign-In, etc.) if needed
3. Configure Firebase Analytics
4. Set up Firebase Cloud Messaging for notifications (optional)

## Support

For Firebase-specific issues, refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

