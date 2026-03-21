import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/auth.dart';
import 'email_verification_notice_page.dart';
import 'password_reset_notice_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(emailController.text.trim()),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) {
      return;
    }

    final ok = await AuthService.sendPasswordResetEmail(email: email);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PasswordResetNoticePage(
          email: email,
          emailSent: ok,
          errorMessage: AuthService.lastPasswordResetError,
        ),
      ),
    );
  }

  String _readableAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'No account found for that email.',
      'wrong-password' => 'Incorrect password.',
      'invalid-email' => 'Please enter a valid email address.',
      'invalid-credential' =>
        'Email or password is incorrect. Please check and try again.',
      'invalid-login-credentials' =>
        'Email or password is incorrect. Please check and try again.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Network error. Check your internet connection and try again.',
      _ => e.message?.isNotEmpty == true
          ? e.message!
          : 'Login failed (${e.code}). Please try again.',
    };
  }

  Future<void> _login() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('LoginPage: Attempting to sign in with email: $email');
      await AuthService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      debugPrint('LoginPage: Sign in completed successfully');

      final isEmailVerified = await AuthService.refreshAndSyncEmailVerification();
      if (!isEmailVerified) {
        await AuthService.sendVerificationEmailToCurrentUser();
        return;
      }

      // Ensure user document exists
      await AuthService.ensureCurrentUserDocumentExists();

      // AuthGate handles navigation based on the user's role.
    } on FirebaseAuthException catch (e) {
      debugPrint('LoginPage: Firebase Auth Exception: ${e.code} - ${e.message}');
      messenger.showSnackBar(
        SnackBar(content: Text('${_readableAuthError(e)} [code: ${e.code}]')),
      );
    } catch (e) {
      debugPrint('LoginPage: Unexpected error during login: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF0A1630), Color(0xFF123A6D)]
        : const [Colors.blueAccent, Colors.lightBlueAccent];
    final cardColor = isDark ? const Color(0xFF0F233F) : Colors.white;
    final titleColor = isDark ? const Color(0xFF79B6FF) : Colors.blueAccent;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey;
    final inputFill = isDark ? const Color(0xFF1A355B) : Colors.grey.shade100;
    final buttonColor = isDark ? const Color(0xFF2E80F0) : Colors.blueAccent;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: shellTopColors,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 10,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 80,
                        color: titleColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CinnaLink',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 18,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputFill,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputFill,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          "Don't have an account? Register now",
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9ACBFF)
                                : Colors.blueAccent,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _forgotPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9ACBFF)
                                : Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}