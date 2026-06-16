// lib/core/constants/auth_form_validators.dart

/// Form validation utilities for authentication screens.
class AuthFormValidators {
  AuthFormValidators._();

  static final _emailRegex =
  RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // +20 followed by Egyptian operator prefix (10/11/12/15) then 8 digits
  static final _egyptianE164Regex = RegExp(r'^\+201[0125]\d{8}$');

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return 'كلمات المرور غير متطابقة';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'يجب أن يكون الاسم حرفين على الأقل';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final e164 = toE164(value.trim());
    if (!_egyptianE164Regex.hasMatch(e164)) {
      return 'رقم الهاتف غير صحيح (مثال: 01XXXXXXXXX)';
    }
    return null;
  }

  /// Normalises Egyptian phone input to E.164 (+20XXXXXXXXXX).
  ///
  /// Accepted input forms:
  ///   01XXXXXXXXX   (11 digits, local)
  ///   +2001XXXXXXXXX (already E.164)
  ///   002001XXXXXXXXX (00-prefix international)
  static String toE164(String input) {
    var v = input.trim().replaceAll(' ', '').replaceAll('-', '');

    // 00-prefix international → strip 00, add +
    if (v.startsWith('00')) {
      v = '+${v.substring(2)}';
    }

    // Already E.164
    if (v.startsWith('+')) {
      return v;
    }

    // Local Egyptian: 01XXXXXXXXX (11 digits)
    if (v.startsWith('01') && v.length == 11) {
      return '+20${v.substring(1)}';
    }

    // Cannot normalise — return as-is so validation rejects it.
    return v;
  }
}