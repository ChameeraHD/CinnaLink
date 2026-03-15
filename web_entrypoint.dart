// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cinnalink/firebase_options.dart';
import 'package:cinnalink/main.dart' as app_main;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for web
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the main app
  app_main.main();
}
