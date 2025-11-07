import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current app user with role
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting app user: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final appUser = await getCurrentAppUser();
        if (appUser != null && appUser.role == role) {
          // Update last login
          await _firestore.collection('users').doc(appUser.uid).update({
            'lastLogin': DateTime.now().toIso8601String(),
          });
          return appUser.copyWith(lastLogin: DateTime.now());
        } else {
          await signOut();
          throw Exception('Invalid role for this account');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Register new user
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final appUser = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName ?? userCredential.user!.displayName,
          role: role,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          additionalData: additionalData,
        );

        // Save user to Firestore
        await _firestore.collection('users').doc(appUser.uid).set(appUser.toJson());

        // Update display name if provided
        if (displayName != null) {
          await userCredential.user!.updateDisplayName(displayName);
        }

        return appUser;
      }
      throw Exception('User creation failed');
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['displayName'] = displayName;
        await user.updateDisplayName(displayName);
      }
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
        await user.updatePhoneNumber(PhoneAuthProvider.credential(
          verificationId: '',
          smsCode: phoneNumber,
        ));
      }
      if (additionalData != null) {
        updates['additionalData'] = additionalData;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}

