// lib/core/theme/app_radius.dart
import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 24;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}