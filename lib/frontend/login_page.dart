import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/auth.dart';
import 'password_reset_notice_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  final List<_DecorCircle> _decorCircles = [
    _DecorCircle(
      size: 90,
      baseDx: 0.15,
      baseDy: 0.17,
      color: const Color(0x4D8E7EFF),
      speed: 1.0,
      direction: 1,
    ),
    _DecorCircle(
      size: 64,
      baseDx: 0.82,
      baseDy: 0.12,
      color: const Color(0x45879DF5),
      speed: 1.3,
      direction: -1,
    ),
    _DecorCircle(
      size: 100,
      baseDx: 0.30,
      baseDy: 0.75,
      color: const Color(0x4D9D7EFF),
      speed: 0.9,
      direction: 1,
    ),
    _DecorCircle(
      size: 72,
      baseDx: 0.78,
      baseDy: 0.68,
      color: const Color(0x4D6E53F2),
      speed: 1.1,
      direction: -1,
    ),
    _DecorCircle(
      size: 46,
      baseDx: 0.50,
      baseDy: 0.40,
      color: const Color(0x6AB6A0FF),
      speed: 1.5,
      direction: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation1 =
        ColorTween(
          begin: const Color(0xFF1D316B),
          end: const Color(0xFF5247AD),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _colorAnimation2 =
        ColorTween(
          begin: const Color(0xFF2F54B3),
          end: const Color(0xFF8469E8),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
            onPressed: () =>
                Navigator.of(context).pop(emailController.text.trim()),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    final ok = await AuthService.sendPasswordResetEmail(email: email);

    if (!mounted) return;

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
      _ =>
        e.message?.isNotEmpty == true
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

    setState(() => _isLoading = true);

    try {
      await AuthService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      final isEmailVerified =
          await AuthService.refreshAndSyncEmailVerification();
      if (!isEmailVerified) {
        await AuthService.sendVerificationEmailToCurrentUser();
        return;
      }

      await AuthService.ensureCurrentUserDocumentExists();
      await AuthService.ensureSuperAdminSetup();
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${_readableAuthError(e)} [code: ${e.code}]')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shellTopColors = [
      _colorAnimation1.value ?? const Color(0xFF1D316B),
      _colorAnimation2.value ?? const Color(0xFF8469E8),
    ];
    final cardColor = Colors.white.withOpacity(0.92);
    final titleColor = const Color(0xFF2A3A88);
    final subtitleColor = const Color(0xFF5F6EA8);
    final inputFill = const Color(0xFFE8EBFF);
    final buttonColor = const Color(0xFF5766C1);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final t = _animationController.value;
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: shellTopColors,
                  ),
                ),
              ),
              ..._decorCircles.map((circle) {
                final dx =
                    circle.baseDx +
                    sin(t * 2 * pi * circle.speed + circle.direction) * 0.03;
                final dy =
                    circle.baseDy +
                    cos(t * 2 * pi * circle.speed + circle.direction) * 0.03;
                return Positioned(
                  left: MediaQuery.of(context).size.width * dx,
                  top: MediaQuery.of(context).size.height * dy,
                  child: Transform.scale(
                    scale:
                        0.86 +
                        sin(t * 2 * pi * circle.speed + circle.direction) *
                            0.06,
                    child: Container(
                      width: circle.size,
                      height: circle.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circle.color,
                        boxShadow: [
                          BoxShadow(
                            color: circle.color.withOpacity(0.25),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      elevation: 14,
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
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
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
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              ),
                              child: const Text(
                                "Don't have an account? Register now",
                                style: TextStyle(color: Color(0xFF5766C1)),
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(color: Color(0xFF5766C1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DecorCircle {
  final double size;
  final double baseDx;
  final double baseDy;
  final Color color;
  final double speed;
  final double direction;

  const _DecorCircle({
    required this.size,
    required this.baseDx,
    required this.baseDy,
    required this.color,
    required this.speed,
    required this.direction,
  });
}
