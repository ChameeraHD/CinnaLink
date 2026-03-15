import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'firebase_options.dart';
import 'landowner_dashboard.dart';
import 'login_page.dart';
import 'worker_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = false;

  void toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  } 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinnaLink',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
        print('AuthGate: Auth state changed - ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, User: ${snapshot.data?.uid ?? "null"}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          print('AuthGate: No user data, showing LoginPage');
          return const LoginPage();
        }

        print('AuthGate: User authenticated, fetching role...');
        return FutureBuilder<String?>(
          future: () async {
            // Ensure user document exists before trying to get role
            await AuthService.ensureCurrentUserDocumentExists();
            return AuthService.getCurrentUserRole();
          }(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data;
            print('AuthGate: User role retrieved: $role');

            if (role == 'worker') {
              print('AuthGate: Navigating to WorkerDashboard');
              return const WorkerDashboard();
            } else if (role == 'landowner') {
              print('AuthGate: Navigating to LandownerDashboard');
              return const LandownerDashboard();
            }

            print('AuthGate: No valid role found, showing LoginPage');
            return const LoginPage();
          },
        );
      },
    );
  }
}
