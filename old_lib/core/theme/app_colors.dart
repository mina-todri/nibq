// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Gold / Amber accent
  static const gold50 = Color(0xFFFFF9EC);
  static const gold100 = Color(0xFFFFF0CC);
  static const gold200 = Color(0xFFFFE099);
  static const gold300 = Color(0xFFF5C842);
  static const gold400 = Color(0xFFD4A853);
  static const gold500 = Color(0xFFC8883A);
  static const gold600 = Color(0xFFA06828);
  static const gold700 = Color(0xFF7A4D1A);
  static const gold800 = Color(0xFF53340F);
  static const gold900 = Color(0xFF2C1A06);

  // Neutral ink
  static const ink0 = Color(0xFFFFFFFF);
  static const ink50 = Color(0xFFF5F4F2);
  static const ink100 = Color(0xFFE8E6E2);
  static const ink200 = Color(0xFFC8C5BF);
  static const ink300 = Color(0xFF9A9690);
  static const ink400 = Color(0xFF6E6B66);
  static const ink500 = Color(0xFF4A4845);
  static const ink600 = Color(0xFF313028);
  static const ink700 = Color(0xFF252520);
  static const ink800 = Color(0xFF1A1A16);
  static const ink850 = Color(0xFF161612);
  static const ink900 = Color(0xFF0E0E0B);
  static const ink950 = Color(0xFF080806);

  // Semantic
  static const success = Color(0xFF2ECC78);
  static const successLight = Color(0xFFE8F8F0);
  static const danger = Color(0xFFE05050);
  static const dangerLight = Color(0xFFFDEAEA);
  static const warning = Color(0xFFF5A623);
  static const info = Color(0xFF4A90D9);

  // Surfaces (dark)
  static const surfBg = Color(0xFF0E0E0B);
  static const surfBase = Color(0xFF131310);
  static const surfRaised = Color(0xFF1A1A16);
  static const surfOverlay = Color(0xFF222220);
  static const surfHover = Color(0xFF2A2A26);
  static const surfActive = Color(0xFF323230);

  // Surfaces (light)
  static const surfBgLight = Color(0xFFF5F4F0);
  static const surfBaseLight = Color(0xFFFFFFFF);
  static const surfRaisedLight = Color(0xFFFAF9F6);
  static const surfOverlayLight = Color(0xFFF0EDE8);

  // Borders
  static final borderSubtle = Colors.white.withValues(alpha: 0.06);
  static final borderDefault = Colors.white.withValues(alpha: 0.10);
  static final borderStrong = Colors.white.withValues(alpha: 0.18);
  static final borderAccent = const Color(0xFFD4A853).withValues(alpha: 0.40);

  // Borders light
  static final borderSubtleLight = Colors.black.withValues(alpha: 0.06);
  static final borderDefaultLight = Colors.black.withValues(alpha: 0.10);

  // Text
  static const textPrimary = Color(0xFFF0EDE8);
  static const textSecondary = Color(0xFF9A9690);
  static const textTertiary = Color(0xFF5C5A56);
  static const textDisabled = Color(0xFF3A3836);
  static const textInverse = Color(0xFF0E0E0B);
  static const textAccent = Color(0xFFD4A853);

  // Text light
  static const textPrimaryLight = Color(0xFF1A1A16);
  static const textSecondaryLight = Color(0xFF5C5A56);
  static const textTertiaryLight = Color(0xFF9A9690);
}