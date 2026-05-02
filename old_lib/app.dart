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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.surfBg,
    body: Center(
        child: CircularProgressIndicator(color: AppColors.gold400)),
  );
}

class ArtStudioApp extends ConsumerWidget {
  const ArtStudioApp({super.key});

  static final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      if (next is Unauthenticated || next is AuthError) {
        AppRouter.navigatorKey.currentState
            ?.popUntil((route) => route.isFirst);
      }
      if (next is AuthError) {
        _messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.danger,
        ));
      }
    });

    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();

    return MaterialApp(
      title: 'ستوديو الفنون والعمارة',
      navigatorKey: AppRouter.navigatorKey,
      scaffoldMessengerKey: _messengerKey,
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
      home: Consumer(
        builder: (context, ref, _) {
          final authState = ref.watch(authProvider);
          return switch (authState) {
            AuthInitial() || AuthLoading() => const SplashScreen(),
            Authenticated() => const HomeScreen(),
            Unauthenticated() || AuthError() => const LoginScreen(),
          };
        },
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}