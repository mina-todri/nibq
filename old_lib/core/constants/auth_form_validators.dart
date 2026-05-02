// lib/core/constants/auth_form_validators.dart

class AuthFormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
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
    // Optional: add more complex rules here (e.g., uppercase, numbers)
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
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
    // Supports +9665XXXXXXXX format and basic variants
    final phone = toE164(value.trim());
    if (!RegExp(r'^\+9665\d{8}$').hasMatch(phone) && !RegExp(r'^\+\d{8,15}$').hasMatch(phone)) {
      return 'رقم الهاتف غير صحيح (مثال: +9665XXXXXXXX)';
    }
    return null;
  }

  static String toE164(String input) {
    var v = input.trim().replaceAll(' ', '').replaceAll('-', '');
    if (v.startsWith('00')) v = '+${v.substring(2)}';
    if (v.startsWith('0')) {
       // Assuming Saudi if starts with 05
       if (v.startsWith('05') && v.length == 10) {
         v = '+966${v.substring(1)}';
       } else {
         v = v.substring(1);
       }
    }
    if (!v.startsWith('+')) {
      if (v.startsWith('5') && v.length == 9) {
        v = '+966$v';
      } else {
        v = '+20$v'; // Fallback to Egypt or generic
      }
    }
    return v;
  }
}
