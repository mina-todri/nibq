// lib/core/theme/app_theme.dart
// FIX 5 — Theme system:
//   1. AppBar colors now correctly defined per theme in AppBarTheme
//   2. Text contrast improved — bodyLarge/bodyMedium use proper theme colors
//   3. ElevatedButton, TextButton styles added to prevent invisible buttons
//   4. InputDecorationTheme added for consistent text fields
//   5. Removed hardcoded colors in AppBarTheme that were overriding light theme

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextStyle _body(double size, FontWeight w, {Color? color}) =>
      GoogleFonts.cairo(
          fontSize: size,
          fontWeight: w,
          color: color ?? AppColors.textPrimary,
          height: 1.5);

  static TextStyle _display(double size, FontWeight w, {Color? color}) =>
      GoogleFonts.tajawal(
          fontSize: size,
          fontWeight: w,
          color: color ?? AppColors.textPrimary,
          height: 1.2);

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.gold400,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.gold300,
      onSecondary: AppColors.textInverse,
      tertiary: AppColors.gold500,
      onTertiary: AppColors.textInverse,
      surface: AppColors.surfRaised,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.textInverse,
      outline: AppColors.borderDefault,
      surfaceContainerHighest: AppColors.surfOverlay,
    );

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.surfBg,
      primaryColor: AppColors.gold400,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfBase,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: _display(18, FontWeight.w700, color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: TextTheme(
        displayLarge: _display(32, FontWeight.w900, color: AppColors.textPrimary),
        displayMedium: _display(28, FontWeight.w900, color: AppColors.textPrimary),
        displaySmall: _display(24, FontWeight.w900, color: AppColors.textPrimary),
        headlineLarge: _display(22, FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: _display(20, FontWeight.w700, color: AppColors.textPrimary),
        headlineSmall: _display(18, FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: _display(16, FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: _display(14, FontWeight.w700, color: AppColors.textPrimary),
        titleSmall: _display(12, FontWeight.w700, color: AppColors.textPrimary),
        bodyLarge: _body(16, FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: _body(14, FontWeight.w400, color: AppColors.textPrimary),
        bodySmall: _body(12, FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: _body(14, FontWeight.w600, color: AppColors.textPrimary),
        labelMedium: _body(12, FontWeight.w600, color: AppColors.textSecondary),
        labelSmall: _body(10, FontWeight.w600, color: AppColors.textTertiary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfRaised,
        labelStyle: _body(14, FontWeight.w400, color: AppColors.textSecondary),
        hintStyle: _body(14, FontWeight.w400, color: AppColors.textTertiary),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.gold400, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.danger),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold400,
          foregroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: _body(16, FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold400,
          textStyle: _body(14, FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfRaised,
      ),
      cardColor: AppColors.surfRaised,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.gold400 : AppColors.ink400),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.gold400.withValues(alpha: 0.4)
                : AppColors.ink600),
      ),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.gold400,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.gold500,
      onSecondary: AppColors.textInverse,
      tertiary: AppColors.gold600,
      onTertiary: AppColors.textInverse,
      surface: AppColors.surfRaisedLight,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.danger,
      onError: AppColors.textInverse,
      outline: AppColors.borderDefaultLight,
      surfaceContainerHighest: AppColors.surfOverlayLight,
    );

    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.surfBgLight,
      primaryColor: AppColors.gold400,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfBaseLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: _display(18, FontWeight.w700, color: AppColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfRaisedLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderSubtleLight),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: TextTheme(
        displayLarge: _display(32, FontWeight.w900, color: AppColors.textPrimaryLight),
        displayMedium: _display(28, FontWeight.w900, color: AppColors.textPrimaryLight),
        displaySmall: _display(24, FontWeight.w900, color: AppColors.textPrimaryLight),
        headlineLarge: _display(22, FontWeight.w700, color: AppColors.textPrimaryLight),
        headlineMedium: _display(20, FontWeight.w700, color: AppColors.textPrimaryLight),
        headlineSmall: _display(18, FontWeight.w700, color: AppColors.textPrimaryLight),
        titleLarge: _display(16, FontWeight.w700, color: AppColors.textPrimaryLight),
        titleMedium: _display(14, FontWeight.w700, color: AppColors.textPrimaryLight),
        titleSmall: _display(12, FontWeight.w700, color: AppColors.textPrimaryLight),
        bodyLarge: _body(16, FontWeight.w400, color: AppColors.textPrimaryLight),
        bodyMedium: _body(14, FontWeight.w400, color: AppColors.textPrimaryLight),
        bodySmall: _body(12, FontWeight.w400, color: AppColors.textSecondaryLight),
        labelLarge: _body(14, FontWeight.w600, color: AppColors.textPrimaryLight),
        labelMedium: _body(12, FontWeight.w600, color: AppColors.textSecondaryLight),
        labelSmall: _body(10, FontWeight.w600, color: AppColors.textTertiaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfRaisedLight,
        labelStyle: _body(14, FontWeight.w400, color: AppColors.textSecondaryLight),
        hintStyle: _body(14, FontWeight.w400, color: AppColors.textTertiaryLight),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderDefaultLight),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.gold400, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.danger),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold400,
          foregroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: _body(16, FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold400,
          textStyle: _body(14, FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderSubtleLight,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfRaisedLight,
      ),
      cardColor: AppColors.surfRaisedLight,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.gold400 : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.gold400.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }
}
