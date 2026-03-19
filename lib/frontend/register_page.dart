import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../backend/auth.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _selectedRole = 'worker';
  bool _isLoading = false;

  Future<bool> _checkConnectivity() async {
    try {
      // Simple connectivity check by trying to reach Firebase
      await FirebaseAuth.instance.currentUser?.reload().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Connectivity check timed out'),
      );
      return true;
    } catch (_) {
      // Try a different approach - check if we can create a dummy auth operation
      try {
        // This will fail but should fail quickly if there's no internet
        await FirebaseAuth.instance.signInAnonymously().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('No internet connection'),
        );
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> _register() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (password.length < 6) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Check connectivity first
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network and try again.'),
            duration: Duration(seconds: 5),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      debugPrint('Starting registration process...');
      // Add timeout to prevent indefinite waiting
      final credential = await AuthService.registerUser(
        name: name,
        email: email,
        password: password,
        role: _selectedRole,
      );
      debugPrint('Registration completed successfully');

      if (mounted) {
        final uid = credential.user?.uid;
        if (uid == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Registration succeeded but user session is missing.')),
          );
          return;
        }

        final otpSent = await AuthService.sendEmailOtp(
          uid: uid,
          email: email,
          name: name,
        );

        if (!mounted) {
          return;
        }

        await AuthService.signOut();

        if (!mounted) {
          return;
        }

        if (!otpSent) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Account created, but OTP email failed. Please try resend on verification page.'),
            ),
          );
        }

        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              uid: uid,
              email: email,
              name: name,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        if (verified == true) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Account verified. Please login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          return;
        }

        messenger.showSnackBar(
          const SnackBar(
            content: Text('OTP verification is required before you can sign in.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account with this email already exists.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        case 'too-many-requests':
          message = 'Too many registration attempts. Please try again later.';
          break;
        default:
          message = 'Registration failed: ${e.message ?? 'Unknown error'}';
      }
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 80,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join CinnaLink',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        fillColor: Colors.grey[100],
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
                        fillColor: Colors.grey[100],
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'I am a',
                        prefixIcon: const Icon(Icons.work),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'worker',
                          child: Text('Worker'),
                        ),
                        DropdownMenuItem(
                          value: 'landowner',
                          child: Text('Landowner'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Creating account...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}