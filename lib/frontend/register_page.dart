import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../backend/auth.dart';
import 'email_verification_notice_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _selectedRole = 'worker';
  bool _isLoading = false;
  String? _emailErrorText;
  String? _phoneErrorText;

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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _emailErrorText = 'Please enter a valid email address.';
      });
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

    // Simple phone validation - must be at least 10 digits
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }

    // Normalize phone before saving and OTP send (strict E.164).
    final formattedPhone = phoneDigits.startsWith('94')
      ? '+$phoneDigits'
      : phoneDigits.startsWith('0')
        ? '+94${phoneDigits.substring(1)}'
        : '+94$phoneDigits';

    if (_phoneErrorText != null) {
      setState(() {
        _phoneErrorText = null;
      });
    }
    if (_emailErrorText != null) {
      setState(() {
        _emailErrorText = null;
      });
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

    final checkResults = await Future.wait<bool>([
      AuthService.isPhoneNumberInUse(phone: formattedPhone),
      AuthService.isEmailInUse(email: email),
    ]);
    final isPhoneTaken = checkResults[0];
    final isEmailTaken = checkResults[1];

    if (isPhoneTaken || isEmailTaken) {
      if (mounted) {
        setState(() {
          _phoneErrorText =
              isPhoneTaken ? 'This phone number is already used.' : null;
          _emailErrorText = isEmailTaken ? 'This email is already used.' : null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      debugPrint('Starting registration process...');
      // Add timeout to prevent indefinite waiting
      await AuthService.registerUser(
        name: name,
        email: email,
        phone: formattedPhone,
        password: password,
        role: _selectedRole,
        darkModeEnabled: isDarkTheme,
      );
      debugPrint('Registration completed successfully');

      if (mounted) {
        final emailLinkSent = await AuthService.sendVerificationEmailToCurrentUser();

        await AuthService.signOut();

        if (!mounted) {
          return;
        }

        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationNoticePage(
              email: email,
              emailSent: emailLinkSent,
              errorMessage: AuthService.lastVerificationEmailError,
              resendPassword: password,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          if (mounted) {
            setState(() {
              _emailErrorText = 'This email is already used.';
            });
          }
          return;
        case 'invalid-email':
          if (mounted) {
            setState(() {
              _emailErrorText = 'Please enter a valid email address.';
            });
          }
          return;
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
      final text = e.toString();
      if (text.contains('This phone number is already used.')) {
        if (mounted) {
          setState(() {
            _phoneErrorText = 'This phone number is already used.';
          });
        }
        return;
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF0A1630), Color(0xFF123A6D)]
        : const [Colors.blueAccent, Colors.lightBlueAccent];
    final cardColor = isDark ? const Color(0xFF0F233F) : Colors.white;
    final titleColor = isDark ? const Color(0xFF79B6FF) : Colors.blueAccent;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey;
    final inputFill = isDark ? const Color(0xFF1A355B) : Colors.grey.shade100;
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final inputHintColor = isDark ? Colors.white60 : Colors.black54;
    final inputIconColor = isDark ? const Color(0xFF9ACBFF) : Colors.black54;
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
                        Icons.person_add,
                        size: 80,
                        color: titleColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join CinnaLink',
                        style: TextStyle(
                          fontSize: 18,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _nameController,
                        style: TextStyle(color: inputTextColor),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: inputHintColor),
                          hintStyle: TextStyle(color: inputHintColor),
                          prefixIcon: Icon(Icons.person, color: inputIconColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputFill,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_emailErrorText != null) {
                            setState(() {
                              _emailErrorText = null;
                            });
                          }
                        },
                        style: TextStyle(color: inputTextColor),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          errorText: _emailErrorText,
                          labelStyle: TextStyle(color: inputHintColor),
                          hintStyle: TextStyle(color: inputHintColor),
                          prefixIcon: Icon(Icons.email, color: inputIconColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputFill,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (_phoneErrorText != null) {
                            setState(() {
                              _phoneErrorText = null;
                            });
                          }
                        },
                        style: TextStyle(color: inputTextColor),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g., +94 77 1234567 or 0771234567',
                          errorText: _phoneErrorText,
                          labelStyle: TextStyle(color: inputHintColor),
                          hintStyle: TextStyle(color: inputHintColor),
                          prefixIcon: Icon(Icons.phone, color: inputIconColor),
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
                        style: TextStyle(color: inputTextColor),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: inputHintColor),
                          hintStyle: TextStyle(color: inputHintColor),
                          prefixIcon: Icon(Icons.lock, color: inputIconColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputFill,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        style: TextStyle(color: inputTextColor),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: inputHintColor),
                          hintStyle: TextStyle(color: inputHintColor),
                          prefixIcon: Icon(Icons.lock_outline, color: inputIconColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputFill,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        style: TextStyle(color: inputTextColor),
                        dropdownColor: isDark ? const Color(0xFF1A355B) : Colors.white,
                        decoration: InputDecoration(
                          labelText: 'I am a',
                          labelStyle: TextStyle(color: inputHintColor),
                          hintStyle: TextStyle(color: inputHintColor),
                          prefixIcon: Icon(Icons.work, color: inputIconColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: inputFill,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'worker',
                            child: Text('Worker', style: TextStyle(color: inputTextColor)),
                          ),
                          DropdownMenuItem(
                            value: 'landowner',
                            child: Text('Landowner', style: TextStyle(color: inputTextColor)),
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
                            backgroundColor: buttonColor,
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
                        child: Text(
                          'Already have an account? Login',
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}