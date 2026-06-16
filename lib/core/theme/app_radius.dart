// lib/core/theme/app_radius.dart

import 'package:flutter/material.dart';

/// Border-radius design tokens.
///
/// Changes vs original:
/// - [IMPROVEMENT] Added `BorderRadius` constants for the most commonly used
///   radii so callers don't need to construct `BorderRadius.circular()` at
///   every call site (avoids repeated object allocation in build methods).
/// - [IMPROVEMENT] `all()` helper kept for dynamic/runtime radius computation.
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 24;

  // Pre-constructed BorderRadius constants — use these in const widgets.
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));

  /// Dynamic helper for runtime-computed radii.
  static BorderRadius all(double r) => BorderRadius.circular(r);
}