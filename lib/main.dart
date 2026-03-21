import 'package:cinnalink/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this
 // Add this
import 'backend/auth.dart';
import 'firebase_options.dart';
import 'frontend/landowner_dashboard.dart';
import 'frontend/login_page.dart';
import 'frontend/email_verification_notice_page.dart';
import 'frontend/worker_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _darkMode = false;
  // 1. Added Locale variable
  
  Locale _locale = const Locale('en');

  void toggleDarkMode(bool value) {
    if (_darkMode == value) return;
    setState(() {
      _darkMode = value;
    });
  }

  // 2. Added method to change language globally
  void setLocale(Locale value) {
    if (_locale == value) return;
    setState(() {
      _locale = value;
    });
  }

  ThemeData _buildLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8F7),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      cardTheme: const CardThemeData(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7EC8A2),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0E1513),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      cardTheme: CardThemeData(
        color: const Color(0xFF16211E),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2A25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF141E1B),
        selectedItemColor: scheme.primary,
        unselectedItemColor: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinnaLink',
      debugShowCheckedModeBanner: false,
      // 3. Bind the current locale and localization delegates
      
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
HEAD
        print(
          'AuthGate: Auth state changed - ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, User: ${snapshot.data?.uid ?? "null"}',
        );


c6d881f5c993b9dbf9e68a67b302ff055b600222
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final user = snapshot.data;
        final appState = MyApp.of(context);
        return FutureBuilder<String?>(
          future: () async {
            await AuthService.ensureCurrentUserDocumentExists();
            final profile = await AuthService.getCurrentUserProfile();
            
            // --- Sync Settings from Firestore ---
            if (profile != null) {
              // Sync Dark Mode
              final darkModeEnabled = profile['darkModeEnabled'] == true;
              appState?.toggleDarkMode(darkModeEnabled);

              // Sync Language
              String? savedLang = profile['language'];
              if (savedLang != null) {
                if (savedLang == 'Tamil') {
                  appState?.setLocale(const Locale('ta'));
                } else if (savedLang == 'Sinhala') appState?.setLocale(const Locale('si'));
                else appState?.setLocale(const Locale('en'));
              }
            }

            final isVerified = await AuthService.refreshAndSyncEmailVerification();
            if (!isVerified) {
              return '__unverified__';
            }

            return AuthService.getCurrentUserRole();
          }(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final role = roleSnapshot.data;
            if (role == '__unverified__') {
              return EmailVerificationNoticePage(
                email: user?.email ?? '',
                emailSent: AuthService.lastVerificationEmailSent ?? true,
                errorMessage: AuthService.lastVerificationEmailError,
              );
            }
            if (role == 'landowner') return const LandownerDashboard();
            return const WorkerDashboard();
          },
        );
      },
    );
  }
}