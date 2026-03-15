import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of authentication state changes.
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Signs in with email/password.
  static Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    print('AuthService: Signing in with email: $email');
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('AuthService: Sign in successful for user: ${credential.user?.uid}');
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
        print('AuthService: User document does not exist, creating it...');
        // Try to create a basic document if it doesn't exist
        // This is a fallback for users who might have been created without proper documents
        await docRef.set({
          'email': user.email ?? '',
          'role': 'worker', // Default to worker if not specified
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('AuthService: Created fallback user document');
      } else {
        // If document exists, ensure it has a role
        final data = doc.data();
        if (data != null && (data['role'] == null || !(data['role'] is String) || !(data['role'] == 'worker' || data['role'] == 'landowner'))) {
          print('AuthService: User document exists but role is invalid, setting to worker...');
          await docRef.set({
            'role': 'worker',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('AuthService: Updated user document with default role');
        }
      }
    } catch (e) {
      print('AuthService: Error ensuring user document: $e');
      // If offline or error, continue without failing
    }
  }

  /// Signs out the current user.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Gets the current user's role from Firestore.
  ///
  /// Expects a document in `users/{uid}` with a field `role` set to either
  /// `worker` or `landowner`.
  static Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    print('AuthService: Getting role for user: ${user?.uid ?? "null"}');

    if (user == null) {
      print('AuthService: No current user found');
      return null;
    }

    // Try up to 3 times with delays in case of timing issues
    for (int attempt = 1; attempt <= 3; attempt++) {
      print('AuthService: Attempt $attempt to get user role');

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        print('AuthService: Document exists: ${doc.exists}');

        if (doc.exists) {
          final data = doc.data();
          print('AuthService: Document data: $data');

          if (data != null) {
            final role = data['role'];
            print('AuthService: Retrieved role: $role');
            if (role is String && (role == 'worker' || role == 'landowner')) {
              return role;
            }
          }
        }

        // Wait before retrying (except on the last attempt)
        if (attempt < 3) {
          print('AuthService: Waiting before retry...');
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        print('AuthService: Error getting user role: $e');
        // If offline or error, break and default
        break;
      }
    }

    print('AuthService: No valid role found, defaulting to worker');
    return 'worker';
  }

  /// Creates a Firebase Auth user and a matching Firestore user document.
  ///
  /// This can be used to bootstrap test accounts in the Firebase console.
  static Future<UserCredential> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    print('AuthService: Starting user registration for $email');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('AuthService: Firebase Auth user created with UID: ${credential.user!.uid}');

    try {
      await _setUserDocument(
        uid: credential.user!.uid,
        name: name,
        role: role,
        email: email,
      );
      print('AuthService: User document set in Firestore');
    } catch (e) {
      print('AuthService: Failed to set user document: $e');
      // Continue anyway, as the user is created in Auth
    }

    return credential;
  }

  static Future<void> _setUserDocument({
    required String uid,
    required String name,
    required String role,
    required String email,
  }) async {
    print('AuthService: Setting user document for UID: $uid');
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'role': role,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    print('AuthService: User document successfully saved to Firestore');
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
      print('AuthService: Error getting user profile: $e');
      return null;
    }
  }

  /// Updates the current user's profile data in Firestore.
  static Future<void> updateCurrentUserProfile(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      print('AuthService: Error updating user profile: $e');
      // Continue without failing
    }
  }
}
