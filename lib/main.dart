import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Robust Firebase initialization to prevent duplicate-app errors
  // Handles: first launch, hot restart, and edge cases
  await _initializeFirebase();
  
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeFirebase() async {
  try {
    // Try to initialize - this will throw if already initialized
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // If it's a duplicate-app error, Firebase is already initialized - that's fine
    if (e.code != 'duplicate-app') {
      rethrow;
    }
    // Already initialized, nothing to do
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nibq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.login,
    );
  }
}
