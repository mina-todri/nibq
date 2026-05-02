// lib/firebase_options.dart
// FIX 8 — Firebase Platform Configuration:
//   Project was configured for web, macOS, and Windows by mistake.
//   This app targets Android and iOS only.
//   Removed: web, macOS, Windows configurations.
//   Kept: Android, iOS.
//   The actual API keys below are REAL keys from the project —
//   they have not been changed, only unreachable platforms removed.

// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // FIX 8: Removed web check — this app is not a web app
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web. '
        'This app targets Android and iOS only.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      // FIX 8: macOS and Windows removed — not supported targets
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for macOS.');
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Windows.');
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1CXxC0SJVEiDktkyFjpbhzZ_c5jzet1Y',
    appId: '1:956047851248:android:90791037477555804b4c35',
    messagingSenderId: '956047851248',
    projectId: 'nibq-app',
    storageBucket: 'nibq-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCYo3G8GKPYgc91t421CkJ6J1CQ-UPprXA',
    appId: '1:956047851248:ios:bc09a5de54ea6e974b4c35',
    messagingSenderId: '956047851248',
    projectId: 'nibq-app',
    storageBucket: 'nibq-app.firebasestorage.app',
    iosBundleId: 'com.example.nibq',
  );
}
