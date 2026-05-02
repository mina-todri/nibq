// lib/core/constants/app_constants.dart
import 'package:intl/intl.dart';

class AppConstants {
  static const String adminEmail = 'admin@example.com';
  static const double taxRate = 0.14;
  static const String taxRateLabel = 'الضريبة (14%)';

  static const String cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  
  static String formatEGP(double price) {
    final format = NumberFormat.currency(
      locale: 'ar_EG',
      symbol: 'جنيه',
      decimalDigits: 0,
    );
    return format.format(price);
  }
}
