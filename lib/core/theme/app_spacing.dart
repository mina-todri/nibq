// lib/core/theme/app_spacing.dart

import 'package:flutter/material.dart';

/// Spacing design tokens (4-point grid system).
///
/// Changes vs original:
/// - [IMPROVEMENT] Added pre-constructed `EdgeInsets` constants for the most
///   common padding patterns — avoids repeated `EdgeInsets` allocation in
///   build methods and encourages consistent spacing application.
/// - [IMPROVEMENT] Added `SizedBox` height/width helpers for spacing between
///   widgets in Column/Row layouts.
class AppSpacing {
  AppSpacing._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  /// Standard horizontal screen padding.
  static const double screen = 20;

  // ── Common EdgeInsets constants ────────────────────────────────────────────
  static const EdgeInsets screenPadding =
  EdgeInsets.symmetric(horizontal: screen);

  static const EdgeInsets allS2 = EdgeInsets.all(s2);
  static const EdgeInsets allS3 = EdgeInsets.all(s3);
  static const EdgeInsets allS4 = EdgeInsets.all(s4);
  static const EdgeInsets allS6 = EdgeInsets.all(s6);

  static const EdgeInsets hS4 = EdgeInsets.symmetric(horizontal: s4);
  static const EdgeInsets hS6 = EdgeInsets.symmetric(horizontal: s6);
  static const EdgeInsets vS2 = EdgeInsets.symmetric(vertical: s2);
  static const EdgeInsets vS4 = EdgeInsets.symmetric(vertical: s4);

  // ── Gap widgets ────────────────────────────────────────────────────────────
  static const Widget gap1 = SizedBox(width: s1, height: s1);
  static const Widget gap2 = SizedBox(width: s2, height: s2);
  static const Widget gap3 = SizedBox(width: s3, height: s3);
  static const Widget gap4 = SizedBox(width: s4, height: s4);
  static const Widget gap6 = SizedBox(width: s6, height: s6);
  static const Widget gap8 = SizedBox(width: s8, height: s8);

  static const Widget hGap2 = SizedBox(width: s2);
  static const Widget hGap3 = SizedBox(width: s3);
  static const Widget hGap4 = SizedBox(width: s4);

  static const Widget vGap2 = SizedBox(height: s2);
  static const Widget vGap3 = SizedBox(height: s3);
  static const Widget vGap4 = SizedBox(height: s4);
  static const Widget vGap6 = SizedBox(height: s6);
  static const Widget vGap8 = SizedBox(height: s8);
}