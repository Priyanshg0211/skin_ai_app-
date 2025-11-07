# How SAGAlyze Works - Complete System Architecture

## 📱 Application Flow Overview

```
App Start → Splash Screen → Check Auth → Role Selection / Dashboard
```

## 🔄 Complete User Journey

### 1. **App Initialization** (`main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase first
  runApp(const MyApp());
}
```

**What happens:**
- Firebase is initialized before the app starts
- This connects your app to Firebase services (Auth, Firestore, Storage)
- The app then shows the `SplashScreen`

---

### 2. **Splash Screen** (`splash_screen.dart`)

**Flow:**
1. Shows animated splash screen (2 seconds)
2. Checks if user is already logged in:
   ```dart
   final user = await authService.getCurrentAppUser();
   ```
3. **If logged in:** Navigate directly to their role-specific dashboard
4. **If not logged in:** Navigate to `RoleSelectionScreen`

**Why this matters:**
- Users don't need to login every time
- Seamless experience for returning users
- Role-based automatic routing

---

### 3. **Role Selection Screen** (`role_selection_screen.dart`)

**What you see:**
- 4 cards, one for each account type:
  - 🔴 **Admin** - Full system access
  - 🔵 **Clinician** - Patient records & analysis
  - 🟢 **Patient** - View own records
  - 🟠 **Receptionist** - Registration & scheduling

**What happens when you tap:**
- Navigates to `LoginScreen` with the selected role
- The role is passed as a parameter to customize the login experience

---

### 4. **Login Screen** (`login_screen.dart`)

**Two modes:**
- **Login Mode:** Sign in with existing account
- **Register Mode:** Create new account (toggle button)

**Login Process:**
```dart
1. User enters email & password
2. AuthService.signInWithEmailAndPassword() is called
3. Firebase Auth verifies credentials
4. If valid, fetches user role from Firestore
5. Verifies role matches selected role type
6. Updates lastLogin timestamp
7. Navigates to appropriate dashboard
```

**Registration Process:**
```dart
1. User enters name, email, password, phone (optional)
2. AuthService.registerWithEmailAndPassword() is called
3. Firebase Auth creates new user account
4. Creates AppUser document in Firestore with role
5. Returns AppUser object
6. Navigates to appropriate dashboard
```

**Security Check:**
- Role validation: If you try to login as "Clinician" but your account is "Patient", login fails
- This prevents unauthorized access

---

## 🔐 Authentication System (`auth_service.dart`)

### How Authentication Works

**1. Firebase Auth (User Identity)**
- Stores: Email, Password, UID (unique user ID)
- Handles: Login, Registration, Password Reset
- Location: Firebase Authentication service

**2. Firestore (User Profile)**
- Stores: Role, Display Name, Phone, Additional Data
- Collection: `users/{uid}`
- Structure:
  ```json
  {
    "uid": "abc123",
    "email": "doctor@clinic.com",
    "displayName": "Dr. Smith",
    "role": "clinician",
    "phoneNumber": "+1234567890",
    "createdAt": "2024-01-01T00:00:00Z",
    "lastLogin": "2024-01-15T10:30:00Z"
  }
  ```

**Why Two Systems?**
- **Firebase Auth:** Fast, secure authentication
- **Firestore:** Flexible user data storage (role, preferences, etc.)

### Key Methods

**`signInWithEmailAndPassword()`**
```dart
1. Authenticate with Firebase Auth
2. Get user's Firestore document
3. Verify role matches requested role
4. Update lastLogin
5. Return AppUser object
```

**`registerWithEmailAndPassword()`**
```dart
1. Create account in Firebase Auth
2. Create AppUser document in Firestore
3. Set role based on registration screen
4. Return AppUser object
```

**`getCurrentAppUser()`**
```dart
1. Get current Firebase Auth user
2. Fetch user document from Firestore
3. Return AppUser with full profile
```

---

## 👥 Role-Based Access Control

### User Roles (`user_role.dart`)

Each role has:
- **Display Name:** How it appears in UI
- **Description:** What they can do
- **Permissions:** What they can access

**Role Permissions:**

| Role | Patient Records | Create Patients | Analysis Tools | Admin Access |
|------|----------------|-----------------|----------------|--------------|
| Admin | ✅ All | ✅ Yes | ✅ Yes | ✅ Yes |
| Clinician | ✅ All | ✅ Yes | ✅ Yes | ❌ No |
| Receptionist | ✅ All | ✅ Yes | ❌ No | ❌ No |
| Patient | ✅ Own Only | ❌ No | ❌ No | ❌ No |

**How it works:**
```dart
// Example: Checking if user can access patient records
if (user.role.canAccessPatientRecords) {
  // Show patient list
} else {
  // Show only own records
}
```

---

## 🏥 Patient ERP System

### Data Storage Architecture

**Firestore Collections:**

```
users/
  └── {userId}/
      ├── uid, email, role, displayName, etc.

patients/
  └── {patientId}/
      ├── id, name, dateOfBirth, gender, etc.
      └── visits/ (subcollection)
          └── {visitId}/
              ├── date, condition, confidence
              ├── rednessIndex, lesionArea, pigmentation
              ├── notes, symptoms
              └── imageUrl (reference to Storage)
```

**Firebase Storage:**
```
patients/
  └── {patientId}/
      └── visits/
          └── {timestamp}.jpg (visit images)
```

### Patient Service (`firebase_patient_service.dart`)

**Key Operations:**

**1. Get All Patients**
```dart
getAllPatients({userId})
```
- **If userId provided:** Returns only that patient's record (for Patient portal)
- **If no userId:** Returns all patients (for Clinicians/Admins)
- Automatically loads visits for each patient

**2. Save Patient**
```dart
savePatient(Patient patient)
```
- Saves patient document to Firestore
- Updates `lastVisit` if visits exist
- Handles userId linking for patient portal

**3. Save Visit**
```dart
savePatientVisit(patientId, PatientVisit visit)
```
- Uploads image to Firebase Storage
- Gets download URL
- Saves visit document in `patients/{id}/visits/`
- Updates patient's `lastVisit` field

**4. Get Visits**
```dart
getPatientVisits(patientId)
```
- Fetches all visits from subcollection
- Downloads images from Storage URLs
- Returns list of PatientVisit objects

---

## 📊 Data Flow Examples

### Example 1: Clinician Analyzing a Skin Image

```
1. Clinician logs in → HomeScreen
2. Selects patient → _selectPatient()
3. Takes/selects image → Image Picker
4. Processes image → TensorFlow Lite model
5. Gets analysis results → Redness, Lesion Area, Condition
6. Saves to patient visit → savePatientVisit()
   ├── Upload image to Storage
   ├── Get download URL
   ├── Save visit data to Firestore
   └── Update patient's lastVisit
7. Visit appears in patient's history
```

### Example 2: Patient Viewing Their Records

```
1. Patient logs in → PatientPortalScreen
2. System queries: getAllPatients(userId: currentUser.uid)
3. Firestore filters: patients where userId == currentUser.uid
4. Loads patient record + all visits
5. Displays visits with images
6. Patient can view details but cannot edit
```

### Example 3: Receptionist Registering New Patient

```
1. Receptionist logs in → ReceptionistDashboardScreen
2. Clicks "Add New Patient" → PatientDetailScreen
3. Fills patient form → Name, DOB, Gender, etc.
4. Saves → savePatient(patient)
5. Patient document created in Firestore
6. Patient can now login with their account
7. Patient record linked via userId (optional)
```

---

## 🔄 Real-Time Synchronization

**How it works:**
- Firestore provides real-time listeners
- When data changes in Firestore, all connected clients update automatically
- No need to manually refresh

**Example:**
```dart
// Stream patients (updates automatically)
streamPatients().listen((patients) {
  setState(() => _patients = patients);
});
```

**Use Cases:**
- Multiple clinicians viewing same patient
- Patient record updates appear instantly
- Visit additions sync across devices

---

## 🛡️ Security & Access Control

### Authentication Level
- **Firebase Auth:** Verifies user identity
- **JWT Tokens:** Automatically managed by Firebase
- **Session Management:** Handled by Firebase SDK

### Authorization Level
- **Role-Based:** Each user has a role in Firestore
- **Permission Checks:** UI and backend check role before actions
- **Firestore Rules:** Server-side security (configure in Firebase Console)

### Data Access
- **Patients:** Can only see their own record (filtered by userId)
- **Clinicians/Admins:** Can see all patients
- **Receptionists:** Can create/edit patients but limited analysis access

---

## 📱 Screen Navigation Flow

```
SplashScreen
    ↓
RoleSelectionScreen
    ↓
LoginScreen (with role)
    ↓
    ├── AdminDashboardScreen
    ├── HomeScreen (Clinician)
    ├── PatientPortalScreen
    └── ReceptionistDashboardScreen
            ↓
    PatientManagementScreen
            ↓
    PatientDetailScreen
            ↓
    PatientVisitScreen
            ↓
    PatientVisitDetailScreen
```

---

## 💾 Data Persistence

### What's Stored Where

**Firebase Authentication:**
- Email, Password (encrypted)
- User UID
- Email verification status

**Cloud Firestore:**
- User profiles (role, name, phone)
- Patient records (demographics, medical history)
- Visit records (analysis results, notes, symptoms)
- Metadata (timestamps, IDs)

**Firebase Storage:**
- Patient visit images (JPEG files)
- Organized by: `patients/{patientId}/visits/{timestamp}.jpg`

### Data Relationships

```
AppUser (Firebase Auth + Firestore)
    ↓ (has userId)
Patient (Firestore)
    ↓ (has patientId)
PatientVisit (Firestore subcollection)
    ↓ (has imageUrl)
Image File (Firebase Storage)
```

---

## 🔧 Key Components Explained

### 1. **AuthService**
- **Purpose:** Handle all authentication operations
- **Key Features:**
  - Login/Registration
  - Role validation
  - Password reset
  - Profile updates
  - Session management

### 2. **FirebasePatientService**
- **Purpose:** Manage patient data in Firebase
- **Key Features:**
  - CRUD operations for patients
  - Visit management
  - Image storage
  - Search functionality
  - Real-time streams

### 3. **UserRole Enum**
- **Purpose:** Define and manage user roles
- **Key Features:**
  - Role definitions
  - Permission checks
  - UI customization
  - Access control

### 4. **AppUser Model**
- **Purpose:** Represent authenticated user
- **Contains:**
  - Firebase Auth UID
  - Email, Display Name
  - Role
  - Profile data
  - Timestamps

### 5. **Patient Model**
- **Purpose:** Represent patient record
- **Contains:**
  - Demographics
  - Medical history
  - Allergies, Medications
  - Visit history
  - userId (for portal access)

---

## 🚀 Performance Optimizations

### 1. **Lazy Loading**
- Visits are loaded only when needed
- Images downloaded on-demand
- Patient list paginated

### 2. **Caching**
- Firebase SDK caches data locally
- Offline support (reads from cache)
- Automatic sync when online

### 3. **Image Optimization**
- Images stored in Storage (not Firestore)
- URLs stored in Firestore
- Download only when viewing

### 4. **Query Optimization**
- Indexed queries in Firestore
- Filtered queries (by userId, date, etc.)
- Subcollections for efficient access

---

## 🔍 Error Handling

**Authentication Errors:**
- Invalid credentials → User-friendly message
- Wrong role → Access denied
- Network issues → Retry mechanism

**Data Errors:**
- Firestore errors → Logged and displayed
- Storage errors → Fallback to base64
- Missing data → Graceful degradation

**User Experience:**
- Loading indicators
- Error messages
- Retry options
- Offline handling

---

## 📈 Scalability

**Current Architecture Supports:**
- ✅ Multiple users simultaneously
- ✅ Large number of patients
- ✅ Many visits per patient
- ✅ High-resolution images
- ✅ Real-time updates
- ✅ Cross-platform (Android/iOS/Web)

**Firebase Handles:**
- Automatic scaling
- Load balancing
- CDN for images
- Global distribution

---

## 🎯 Summary

**The system works by:**

1. **Firebase Auth** handles user identity and login
2. **Firestore** stores all application data (users, patients, visits)
3. **Firebase Storage** stores patient images
4. **Role-based access** controls what each user can see/do
5. **Real-time sync** keeps data updated across devices
6. **Secure by default** with Firebase's built-in security

**Key Benefits:**
- ✅ No backend server needed
- ✅ Automatic scaling
- ✅ Real-time updates
- ✅ Secure by default
- ✅ Offline support
- ✅ Cross-platform

This architecture provides a robust, scalable, and secure patient management system that works seamlessly across all devices and user roles.

