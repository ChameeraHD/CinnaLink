import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._();

  static const String _projectId = 'cinnalink-738f5';
  static const String _functionsRegion = 'us-central1';

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
    _debugLog('AuthService: Sign in successful for user: ${credential.user?.uid}');
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
          'role': 'worker', // Default to worker only for completely missing documents
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
          if (role is String && (role == 'worker' || role == 'landowner')) {
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

  /// Creates a Firebase Auth user and a matching Firestore user document.
  static Future<UserCredential> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _debugLog('AuthService: Starting user registration for $email');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _debugLog('AuthService: Firebase Auth user created with UID: ${credential.user!.uid}');

    try {
      await _setUserDocument(
        uid: credential.user!.uid,
        name: name,
        role: role,
        email: email,
      );
      _debugLog('AuthService: User document set in Firestore');
    } catch (e) {
      _debugLog('AuthService: Failed to set user document: $e');
    }

    return credential;
  }

  static Future<void> _setUserDocument({
    required String uid,
    required String name,
    required String role,
    required String email,
  }) async {
    _debugLog('AuthService: Setting user document for UID: $uid');
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'role': role,
      'email': email,
      'emailVerified': false,
      'requiresOtpVerification': true,
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
      _debugLog('AuthService: Error getting user profile: $e');
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
      _debugLog('AuthService: Error updating user profile: $e');
    }
  }

  static Uri _functionUrl(String functionName) {
    return Uri.parse(
      'https://$_functionsRegion-$_projectId.cloudfunctions.net/$functionName',
    );
  }

  static Future<bool> sendEmailOtp({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      final response = await http.post(
        _functionUrl('sendEmailOtp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'email': email,
          'name': name,
        }),
      );

      if (response.statusCode != 200) {
        _debugLog('AuthService: sendEmailOtp failed (${response.statusCode})');
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      _debugLog('AuthService: sendEmailOtp error: $e');
      return false;
    }
  }

  static Future<bool> verifyEmailOtp({
    required String uid,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        _functionUrl('verifyEmailOtp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'otp': otp}),
      );

      if (response.statusCode != 200) {
        _debugLog('AuthService: verifyEmailOtp failed (${response.statusCode})');
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      _debugLog('AuthService: verifyEmailOtp error: $e');
      return false;
    }
  }
}

