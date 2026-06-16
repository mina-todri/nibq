// lib/app.dart
// FIX 4 — Language switching: MaterialApp.locale is now driven by
//   settings.locale from state. The `builder` wrapping Directionality
//   was the issue — it only changed text direction but NOT the locale
//   that Flutter's localizations framework used. Now both locale AND
//   textDirection are set from the same state variable.
//
// FIX 5 — Theme: MaterialApp now correctly uses themeMode from state.
//   AppBar color fix is in custom_app_bar.dart.

library;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/routing/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'core/models/notification_model.dart';
import 'shared/widgets/notification_toast.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.surfBg,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.gold400)),
      );
}

class ArtStudioApp extends ConsumerWidget {
  const ArtStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth status to reset navigation stack on logout/error
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      if (next is Authenticated && previous is! Authenticated) {
        AppRouter.navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
      }
      if (next is Unauthenticated || next is AuthError) {
        // Clear the entire navigation stack when unauthenticated
        AppRouter.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
      
      if (next is AuthError) {
        final scaffoldContext = AppRouter.navigatorKey.currentContext;
        if (scaffoldContext != null) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    });

    // Listen to new notifications and show In-App banner
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsStreamProvider, (previous, next) {
      final nextList = next.valueOrNull;
      final prevList = previous?.valueOrNull;

      if (nextList != null && prevList != null) {
        final oldIds = prevList.map((n) => n.id).toSet();
        for (final n in nextList) {
          if (!oldIds.contains(n.id)) {
            debugPrint('🔔 New notification detected: ${n.title}');
            // We pass the context, but the Toast now uses the NavigatorKey internally
            NotificationToast.show(context, n);
          }
        }
      }
    });

    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'ستوديو الفنون والعمارة',
      navigatorKey: AppRouter.navigatorKey, // ADDED: for programmatic navigation
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,

      locale: settings.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Removed unnecessary Directionality wrapper that was overwriting locale direction
      home: Consumer(
        builder: (context, ref, _) {
          final authState = ref.watch(authProvider);
          if (authState is AuthInitial) {
            return const SplashScreen();
          }
          if (authState is Authenticated) {
            return const HomeScreen();
          }
          // For Unauthenticated, AuthError, and AuthLoading (during sign-in),
          // show LoginScreen. LoginScreen handles its own loading state.
          return const LoginScreen();
        },
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
