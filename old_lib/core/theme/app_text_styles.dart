// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _display(double size, FontWeight w, {Color? color}) =>
      GoogleFonts.tajawal(
          fontSize: size,
          fontWeight: w,
          color: color ?? AppColors.textPrimary,
          height: 1.2);

  static TextStyle _body(double size, FontWeight w, {Color? color}) =>
      GoogleFonts.cairo(
          fontSize: size,
          fontWeight: w,
          color: color ?? AppColors.textPrimary,
          height: 1.5);

  static TextStyle get display4xl => _display(48, FontWeight.w900);
  static TextStyle get display3xl => _display(36, FontWeight.w900);
  static TextStyle get display2xl => _display(28, FontWeight.w900);
  static TextStyle get displayXl => _display(22, FontWeight.w700);
  static TextStyle get displayLg => _display(18, FontWeight.w700);
  static TextStyle get displayMd => _display(16, FontWeight.w700);

  static TextStyle get bodyLg => _body(16, FontWeight.w400);
  static TextStyle get bodyMd => _body(14, FontWeight.w400);
  static TextStyle get bodySm => _body(12, FontWeight.w400);
  static TextStyle get bodyXs => _body(10, FontWeight.w400);

  static TextStyle get labelMd =>
      _body(14, FontWeight.w600, color: AppColors.textSecondary);
  static TextStyle get caption =>
      _body(12, FontWeight.w400, color: AppColors.textTertiary);
  static TextStyle get buttonLg => _body(16, FontWeight.w700);
  static TextStyle get buttonMd => _body(14, FontWeight.w700);
}