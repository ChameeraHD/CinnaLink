import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static String? _lastVerificationEmailError;
  static String? get lastVerificationEmailError => _lastVerificationEmailError;
  static bool? _lastVerificationEmailSent;
  static bool? get lastVerificationEmailSent => _lastVerificationEmailSent;
  static String? _lastPasswordResetError;
  static String? get lastPasswordResetError => _lastPasswordResetError;

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of authentication state changes.
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Signs in with email/password.
  static Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _debugLog('AuthService: Signing in with email: $email');
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _debugLog(
      'AuthService: Sign in successful for user: ${credential.user?.uid}',
    );
    return credential;
  }

  /// Ensures a user document exists for the current user.
  /// This can be useful if the document was not created during registration.
  static Future<void> ensureCurrentUserDocumentExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    try {
      final doc = await docRef.get();
      if (!doc.exists) {
        _debugLog('AuthService: User document does not exist, creating it...');
        await docRef.set({
          'email': user.email ?? '',
          'role':
              'worker', // Default to worker only for completely missing documents
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _debugLog('AuthService: Created fallback user document');
      }
    } catch (e) {
      _debugLog('AuthService: Error ensuring user document: $e');
    }
  }

  /// Signs out the current user.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Deletes the current user's account and Firestore document.
  static Future<void> deleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      _debugLog('AuthService: Deleting account for user: ${user.uid}');

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      _debugLog('AuthService: Deleted Firestore user document');

      // Delete the Firebase Authentication user
      await user.delete();
      _debugLog('AuthService: Deleted Firebase Auth user');
    } catch (e) {
      _debugLog('AuthService: Error deleting user: $e');
      rethrow;
    }
  }

  /// Gets the current user's role from Firestore.
  static Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    _debugLog('AuthService: Fetching role for user: ${user.uid}');

    final docRef = _firestore.collection('users').doc(user.uid);

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final role = data['role'];
          if (role is String &&
              (role == 'worker' || role == 'landowner' || role == 'admin')) {
            _debugLog('AuthService: Found valid role: $role');
            return role;
          }
        }
      }

      // Self-heal missing/invalid role so authenticated users are not bounced back to login.
      _debugLog('AuthService: No valid role found, defaulting to worker');
      await docRef.set({
        'email': user.email ?? '',
        'role': 'worker',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return 'worker';
    } catch (e) {
      _debugLog('AuthService: Error getting user role: $e');
      // Keep the session usable even when Firestore role read fails.
      return 'worker';
    }
  }

  /// Ensures the super admin (isurub.dev@gmail.com) is properly configured on first login
  static Future<void> ensureSuperAdminSetup() async {
    final user = _auth.currentUser;
    if (user == null) return;

    const superAdminEmail = 'isurub.dev@gmail.com';

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      // If this is the super admin email and isSuperAdmin is not set, set it to true
      if (user.email?.toLowerCase() == superAdminEmail.toLowerCase()) {
        if (!docSnapshot.exists ||
            docSnapshot.data()?['isSuperAdmin'] != true) {
          await userDoc.set({
            'isSuperAdmin': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          _debugLog(
            'AuthService: Super admin setup completed for $superAdminEmail',
          );
        }
      }
    } catch (e) {
      _debugLog('AuthService: Error setting up super admin: $e');
    }
  }

  /// Initializes the super admin account if it doesn't exist
  static Future<void> initializeSuperAdmin() async {
    const superAdminEmail = 'isurub.dev@gmail.com';
    const superAdminPassword = '123456';

    try {
      // Check if super admin user already exists in Firebase Auth
      final adminUsers = await _auth.fetchSignInMethodsForEmail(
        superAdminEmail,
      );

      if (adminUsers.isEmpty) {
        // Create the super admin account
        _debugLog('AuthService: Creating super admin account...');
        final credential = await _auth.createUserWithEmailAndPassword(
          email: superAdminEmail,
          password: superAdminPassword,
        );

        // Create Firestore document for super admin
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': superAdminEmail,
          'role': 'admin',
          'isSuperAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _debugLog('AuthService: Super admin account created successfully');
      } else {
        _debugLog('AuthService: Super admin account already exists');
      }
    } catch (e) {
      _debugLog('AuthService: Error initializing super admin: $e');
    }
  }

  /// Creates a Firebase Auth user and a matching Firestore user document.
  static Future<UserCredential> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    required bool darkModeEnabled,
  }) async {
    final phoneInUse = await isPhoneNumberInUse(phone: phone);
    if (phoneInUse) {
      throw StateError('This phone number is already used.');
    }

    _debugLog('AuthService: Starting user registration for $email');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _debugLog(
      'AuthService: Firebase Auth user created with UID: ${credential.user!.uid}',
    );

    try {
      await _setUserDocument(
        uid: credential.user!.uid,
        name: name,
        role: role,
        email: email,
        phone: phone,
        darkModeEnabled: darkModeEnabled,
      );
      _debugLog('AuthService: User document set in Firestore');
    } catch (e) {
      _debugLog('AuthService: Failed to set user document: $e');
    }

    return credential;
  }

  static Future<bool> isPhoneNumberInUse({required String phone}) async {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: trimmedPhone)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> isEmailInUse({required String email}) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return false;
    }

    final methods = await _auth.fetchSignInMethodsForEmail(trimmedEmail);
    return methods.isNotEmpty;
  }

  static Future<void> _setUserDocument({
    required String uid,
    required String name,
    required String role,
    required String email,
    required String phone,
    required bool darkModeEnabled,
  }) async {
    _debugLog('AuthService: Setting user document for UID: $uid');
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'emailVerified': false,
      'darkModeEnabled': darkModeEnabled,
      'notificationsEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Sends Firebase verification link to current user's email.
  static Future<bool> sendVerificationEmailToCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      _lastVerificationEmailSent = false;
      _lastVerificationEmailError = 'No authenticated user found.';
      return false;
    }

    _lastVerificationEmailError = null;

    try {
      await user.sendEmailVerification();
      _lastVerificationEmailSent = true;
      _debugLog('AuthService: Verification email sent to ${user.email}');
      return true;
    } on FirebaseAuthException catch (e) {
      _debugLog(
        'AuthService: Failed to send verification email: code=${e.code} message=${e.message}',
      );
      _lastVerificationEmailError = switch (e.code) {
        'too-many-requests' =>
          'Too many requests. Please wait a few minutes and try again.',
        'network-request-failed' =>
          'Network error while sending verification email.',
        'invalid-email' => 'Your email address is invalid.',
        _ =>
          e.message?.isNotEmpty == true
              ? e.message
              : 'Could not send verification email right now.',
      };
      _lastVerificationEmailSent = false;
      return false;
    } catch (e) {
      _debugLog('AuthService: Failed to send verification email: $e');
      _lastVerificationEmailError =
          'Could not send verification email right now.';
      _lastVerificationEmailSent = false;
      return false;
    }
  }

  /// Sends password reset email. Password can be changed only via this email link.
  static Future<bool> sendPasswordResetEmail({required String email}) async {
    _lastPasswordResetError = null;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _debugLog('AuthService: Password reset email sent to $email');
      return true;
    } on FirebaseAuthException catch (e) {
      _debugLog(
        'AuthService: Failed to send password reset email: code=${e.code} message=${e.message}',
      );
      _lastPasswordResetError = switch (e.code) {
        'user-not-found' => 'No account found for that email.',
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' =>
          'Too many requests. Please wait a few minutes and try again.',
        'network-request-failed' => 'Network error while sending reset email.',
        _ =>
          e.message?.isNotEmpty == true
              ? e.message
              : 'Could not send password reset email right now.',
      };
      return false;
    } catch (e) {
      _debugLog('AuthService: sendPasswordResetEmail error: $e');
      _lastPasswordResetError =
          'Could not send password reset email right now.';
      return false;
    }
  }

  /// Reloads auth user and syncs email verification status into Firestore.
  static Future<bool> refreshAndSyncEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;
      final isVerified = refreshedUser?.emailVerified == true;

      await _firestore.collection('users').doc(user.uid).set({
        'emailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return isVerified;
    } catch (e) {
      _debugLog('AuthService: Error syncing email verification: $e');
      return false;
    }
  }

  /// Gets the current user's profile data from Firestore.
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      _debugLog('AuthService: Error getting user profile: $e');
      return null;
    }
  }

  /// Updates the current user's profile data in Firestore.
  static Future<void> updateCurrentUserProfile(
    Map<String, dynamic> updates,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update(updates);
      _debugLog('AuthService: Updated user profile');
    } catch (e) {
      _debugLog('AuthService: Error updating user profile: $e');
      rethrow;
    }
  }
}
