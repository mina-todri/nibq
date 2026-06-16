// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Central colour palette for the application.
///
/// Changes vs original:
/// - [FIX] `borderSubtle`, `borderDefault`, `borderStrong`, `borderAccent`,
///   `borderSubtleLight`, `borderDefaultLight` were `static final` computed
///   via `withValues(alpha:)` — these allocated a new Color object on every
///   class reference. Replaced with pre-computed `const Color` values using
///   explicit ARGB hex so they are truly constant and zero-allocation.
/// - [IMPROVEMENT] Added `transparent` alias for convenience.
/// - [IMPROVEMENT] All color groups are documented with their usage context.
class AppColors {
  AppColors._();

  // ── Gold / Amber accent ────────────────────────────────────────────────────
  static const Color gold50 = Color(0xFFFFF9EC);
  static const Color gold100 = Color(0xFFFFF0CC);
  static const Color gold200 = Color(0xFFFFE099);
  static const Color gold300 = Color(0xFFF5C842);
  static const Color gold400 = Color(0xFFD4A853);
  static const Color gold500 = Color(0xFFC8883A);
  static const Color gold600 = Color(0xFFA06828);
  static const Color gold700 = Color(0xFF7A4D1A);
  static const Color gold800 = Color(0xFF53340F);
  static const Color gold900 = Color(0xFF2C1A06);

  // ── Neutral ink (dark-theme foreground scale) ──────────────────────────────
  static const Color ink0 = Color(0xFFFFFFFF);
  static const Color ink50 = Color(0xFFF5F4F2);
  static const Color ink100 = Color(0xFFE8E6E2);
  static const Color ink200 = Color(0xFFC8C5BF);
  static const Color ink300 = Color(0xFF9A9690);
  static const Color ink400 = Color(0xFF6E6B66);
  static const Color ink500 = Color(0xFF4A4845);
  static const Color ink600 = Color(0xFF313028);
  static const Color ink700 = Color(0xFF252520);
  static const Color ink800 = Color(0xFF1A1A16);
  static const Color ink850 = Color(0xFF161612);
  static const Color ink900 = Color(0xFF0E0E0B);
  static const Color ink950 = Color(0xFF080806);

  // ── Semantic colours ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC78);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color danger = Color(0xFFE05050);
  static const Color dangerLight = Color(0xFFFDEAEA);
  static const Color warning = Color(0xFFF5A623);
  static const Color info = Color(0xFF4A90D9);
  static const Color transparent = Color(0x00000000);

  // ── Dark surfaces ──────────────────────────────────────────────────────────
  static const Color surfBg = Color(0xFF0E0E0B);
  static const Color surfBase = Color(0xFF131310);
  static const Color surfRaised = Color(0xFF1A1A16);
  static const Color surfOverlay = Color(0xFF222220);
  static const Color surfHover = Color(0xFF2A2A26);
  static const Color surfActive = Color(0xFF323230);

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color surfBgLight = Color(0xFFF5F4F0);
  static const Color surfBaseLight = Color(0xFFFFFFFF);
  static const Color surfRaisedLight = Color(0xFFFAF9F6);
  static const Color surfOverlayLight = Color(0xFFF0EDE8);

  // ── Dark borders (pre-computed alpha — avoids runtime allocation) ──────────
  // white @ 6 %  → 0x0F (≈ 15)
  static const Color borderSubtle = Color(0x0FFFFFFF);
  // white @ 10 % → 0x1A (≈ 26)
  static const Color borderDefault = Color(0x1AFFFFFF);
  // white @ 18 % → 0x2E (≈ 46)
  static const Color borderStrong = Color(0x2EFFFFFF);
  // gold400 (0xFFD4A853) @ 40 % → 0x66D4A853
  static const Color borderAccent = Color(0x66D4A853);

  // ── Light borders ──────────────────────────────────────────────────────────
  // black @ 6 %  → 0x0F (≈ 15)
  static const Color borderSubtleLight = Color(0x0F000000);
  // black @ 10 % → 0x1A (≈ 26)
  static const Color borderDefaultLight = Color(0x1A000000);

  // ── Dark text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0EDE8);
  static const Color textSecondary = Color(0xFF9A9690);
  static const Color textTertiary = Color(0xFF5C5A56);
  static const Color textDisabled = Color(0xFF3A3836);
  static const Color textInverse = Color(0xFF0E0E0B);
  static const Color textAccent = Color(0xFFD4A853);

  // ── Light text ─────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A16);
  static const Color textSecondaryLight = Color(0xFF5C5A56);
  static const Color textTertiaryLight = Color(0xFF9A9690);
}