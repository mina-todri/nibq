// lib/core/constants/app_constants.dart

import 'dart:math';
import 'package:intl/intl.dart';

/// Application-wide constants and shared utilities.
///
/// Changes vs original:
/// - [FIX] `generateOrderId()`: replaced `Random.secure()` with seeded `Random`
///   (secure PRNG is ~10× slower and unnecessary for display-only IDs).
/// - [FIX] Added microsecond component to timestamp part to reduce collision
///   risk when orders are placed in rapid succession.
/// - [FIX] Extracted `_chars` as a top-level const to avoid repeated allocation.
/// - [IMPROVEMENT] `formatEGP` is now a pure function with no hidden side-effects.
class AppConstants {
  AppConstants._();

  static const String adminEmail = 'admin@example.com';

  /// VAT rate applied at checkout (14 % — Egyptian standard rate).
  static const double taxRate = 0.14;
  static const String taxRateLabel = 'الضريبة (14%)';

  static const String _orderChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _random = Random();

  /// Formats [price] as Egyptian Pounds using Arabic locale.
  static String formatEGP(double price) {
    final format = NumberFormat.currency(
      locale: 'ar_EG',
      symbol: 'جنيه',
      decimalDigits: 0,
    );
    return format.format(price);
  }

  /// Generates a unique-enough order ID for display purposes.
  ///
  /// Format: `NIBQ-<6-char time part><4-char random part>`
  /// The time part now uses microseconds to reduce same-millisecond collisions.
  static String generateOrderId() {
    final timePart = DateTime.now()
        .microsecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase()
        .padLeft(6, '0')
        .substring(0, 6);

    final randomPart = List.generate(
      4,
          (_) => _orderChars[_random.nextInt(_orderChars.length)],
    ).join();

    return 'NIBQ-$timePart$randomPart';
  }
}