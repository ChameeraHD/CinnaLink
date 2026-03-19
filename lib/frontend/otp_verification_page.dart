import 'package:flutter/material.dart';

import '../backend/auth.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.uid,
    required this.email,
    required this.name,
  });

  final String uid;
  final String email;
  final String name;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  Future<void> _verifyOtp() async {
    final messenger = ScaffoldMessenger.of(context);
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP code.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final ok = await AuthService.verifyEmailOtp(uid: widget.uid, otp: otp);

    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifying = false;
    });

    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid or expired OTP. Please try again.')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Email verified. You can now login.')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _resendOtp() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isResending = true;
    });

    final ok = await AuthService.sendEmailOtp(
      uid: widget.uid,
      email: widget.email,
      name: widget.name,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'A new OTP was sent to your email.'
              : 'Could not resend OTP. Try again in a moment.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF121A18), Color(0xFF1D2D2A)]
        : const [Color(0xFF2D7FC1), Color(0xFF58B7E8)];

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
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mark_email_read, size: 68, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Verify Email',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the OTP sent to ${widget.email}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'OTP Code',
                          hintText: '123456',
                          prefixIcon: const Icon(Icons.password),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOtp,
                          child: _isVerifying
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Verifying...'),
                                  ],
                                )
                              : const Text('Verify OTP'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? const Text('Resending...')
                            : const Text('Didn\'t receive code? Resend OTP'),
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
