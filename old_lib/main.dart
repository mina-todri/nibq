// lib/main.dart
// FIXED:
//   1. REMOVED the admin password comment at the end of the original file.
//      That comment contained what appears to be a partial admin credential.
//      Credentials must NEVER be in source code.
//   2. Added FlutterError.onError handler to catch framework-level errors in
//      production instead of crashing silently.

library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (e.g. layout overflow, render errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // In production: log to crashlytics here
    // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final container = ProviderContainer();
  AppRouter.container = container;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ArtStudioApp(),
    ),
  );
}

// ⚠️  SECURITY REMINDER:
// NEVER commit credentials, API keys, or admin passwords to source control.
// Admin accounts should be managed via Firebase Console, not hardcoded here.
