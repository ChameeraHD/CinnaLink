import 'package:flutter/material.dart';
import '../backend/auth.dart';
import 'auth_notice_template.dart';
import '../main.dart';

class EmailVerificationNoticePage extends StatefulWidget {
  const EmailVerificationNoticePage({
    super.key,
    required this.email,
    required this.emailSent,
    this.errorMessage,
    this.resendPassword,
  });

  final String email;
  final bool emailSent;
  final String? errorMessage;
  final String? resendPassword;

  @override
  State<EmailVerificationNoticePage> createState() =>
      _EmailVerificationNoticePageState();
}

class _EmailVerificationNoticePageState extends State<EmailVerificationNoticePage> {
  bool _isResending = false;

  Future<void> _backToLogin() async {
    await AuthService.signOut();
    if (!mounted) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onBackToLoginPressed() {
    _backToLogin();
  }

  Future<void> _resendVerificationEmail() async {
    final messenger = ScaffoldMessenger.of(context);
    final password = widget.resendPassword;
    final currentUser = AuthService.currentUser;

    if (currentUser != null &&
        (currentUser.email ?? '').toLowerCase() == widget.email.toLowerCase()) {
      setState(() {
        _isResending = true;
      });

      final sent = await AuthService.sendVerificationEmailToCurrentUser();

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Verification email resent. Check Inbox/Spam.'
                : 'Resend failed: ${AuthService.lastVerificationEmailError ?? 'Please try again later.'}',
          ),
        ),
      );

      setState(() {
        _isResending = false;
      });
      return;
    }

    final keepDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (password == null || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please log in again to resend the verification email.'),
        ),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await AuthService.signInWithEmailPassword(
        email: widget.email,
        password: password,
      );
      final sent = await AuthService.sendVerificationEmailToCurrentUser();
      await AuthService.signOut();

      if (mounted) {
        MyApp.of(context)?.toggleDarkMode(keepDarkMode);
      }

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Verification email resent. Check Inbox/Spam.'
                : 'Resend failed: ${AuthService.lastVerificationEmailError ?? 'Please try again later.'}',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        MyApp.of(context)?.toggleDarkMode(keepDarkMode);
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not resend right now. Please try logging in again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthNoticeTemplate(
      isSuccess: widget.emailSent,
      title: widget.emailSent
          ? 'Verification Email Sent'
          : 'Could Not Send Verification Email',
      message: widget.emailSent
          ? 'We sent a verification email to:\n${widget.email}\n\nPlease open your Inbox or Spam folder, click the link, then login.'
          : 'We could not send a verification email to:\n${widget.email}\n\n${widget.errorMessage ?? 'Please try logging in again to resend the email.'}',
      secondaryButtonText: _isResending ? 'Resending...' : 'Resend Email',
      secondaryButtonOnPressed: _resendVerificationEmail,
      secondaryButtonLoading: _isResending,
      secondaryButtonLoadingText: 'Resending...',
      primaryButtonText: 'Back to Login',
      primaryButtonOnPressed: _onBackToLoginPressed,
    );
  }
}
