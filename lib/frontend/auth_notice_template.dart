import 'package:flutter/material.dart';

class AuthNoticeTemplate extends StatelessWidget {
  const AuthNoticeTemplate({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    required this.primaryButtonOnPressed,
    this.secondaryButtonText,
    this.secondaryButtonOnPressed,
    this.secondaryButtonLoading = false,
    this.secondaryButtonLoadingText = 'Sending...',
    this.successIcon = Icons.mark_email_read,
    this.errorIcon = Icons.error_outline,
  });

  final bool isSuccess;
  final String title;
  final String message;
  final String primaryButtonText;
  final VoidCallback primaryButtonOnPressed;
  final String? secondaryButtonText;
  final VoidCallback? secondaryButtonOnPressed;
  final bool secondaryButtonLoading;
  final String secondaryButtonLoadingText;
  final IconData successIcon;
  final IconData errorIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final shellTopColors = isDark
        ? const [Color(0xFF0A1630), Color(0xFF123A6D)]
        : const [Color(0xFF2D7FC1), Color(0xFF58B7E8)];
    final cardColor = isDark ? const Color(0xFF0F233F) : Colors.white;
    final bodyTextColor =
        isDark ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.8);
    final secondaryButtonColor =
        isDark ? const Color(0xFF9ACBFF) : colorScheme.primary;
    final primaryButtonColor =
        isDark ? const Color(0xFF2E80F0) : colorScheme.primary;

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
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 10,
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuccess ? successIcon : errorIcon,
                        size: 68,
                        color: isSuccess ? colorScheme.primary : Colors.red,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isSuccess ? colorScheme.primary : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: bodyTextColor,
                        ),
                      ),
                      if (secondaryButtonText != null) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: secondaryButtonLoading
                                ? null
                                : secondaryButtonOnPressed,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: secondaryButtonColor),
                              foregroundColor: secondaryButtonColor,
                            ),
                            child: Text(
                              secondaryButtonLoading
                                  ? secondaryButtonLoadingText
                                  : secondaryButtonText!,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryButtonColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: primaryButtonOnPressed,
                          child: Text(primaryButtonText),
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