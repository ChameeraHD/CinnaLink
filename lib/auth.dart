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
        await docRef.set({
          'email': user.email ?? '',
          'role': 'worker', // Default to worker only for completely missing documents
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('AuthService: Created fallback user document');
      }
    } catch (e) {
      print('AuthService: Error ensuring user document: $e');
    }
  }

  /// Signs out the current user.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Gets the current user's role from Firestore.
  static Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    print('AuthService: Fetching role for user: ${user.uid}');

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final role = data['role'];
          if (role is String && (role == 'worker' || role == 'landowner')) {
            print('AuthService: Found valid role: $role');
            return role;
          }
        }
      }
      print('AuthService: No valid role found in document');
    } catch (e) {
      print('AuthService: Error getting user role: $e');
    }

    return null;
  }

  /// Creates a Firebase Auth user and a matching Firestore user document.
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
    }
  }
}
