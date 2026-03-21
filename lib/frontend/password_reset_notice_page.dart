import 'package:flutter/material.dart';
import '../backend/auth.dart';
import 'auth_notice_template.dart';

class PasswordResetNoticePage extends StatefulWidget {
  const PasswordResetNoticePage({
    super.key,
    required this.email,
    required this.emailSent,
    this.errorMessage,
  });

  final String email;
  final bool emailSent;
  final String? errorMessage;

  @override
  State<PasswordResetNoticePage> createState() =>
      _PasswordResetNoticePageState();
}

class _PasswordResetNoticePageState extends State<PasswordResetNoticePage> {
  bool _isSending = false;
  late bool _emailSent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailSent = widget.emailSent;
    _errorMessage = widget.errorMessage;
  }

  Future<void> _resendResetEmail() async {
    setState(() {
      _isSending = true;
    });

    final sent = await AuthService.sendPasswordResetEmail(email: widget.email);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
      _emailSent = sent;
      _errorMessage = sent ? null : AuthService.lastPasswordResetError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthNoticeTemplate(
      isSuccess: _emailSent,
      title: _emailSent
          ? 'Password Reset Email Sent'
          : 'Could Not Send Reset Email',
      message: _emailSent
          ? 'We sent a password reset link to:\n${widget.email}\n\nOpen your Inbox or Spam folder, then use the link to confirm and set a new password.'
          : 'We could not send a password reset email to:\n${widget.email}\n\n${_errorMessage ?? 'Please try again.'}',
      secondaryButtonText:
          _isSending ? 'Sending...' : 'Resend Reset Email',
      secondaryButtonOnPressed: _resendResetEmail,
      secondaryButtonLoading: _isSending,
      primaryButtonText: 'Back to Login',
      primaryButtonOnPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}