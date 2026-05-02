// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../core/constants/auth_form_validators.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isPhone {
    final v = _emailCtrl.text.trim();
    return v.isNotEmpty && !v.contains('@');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfBg : AppColors.surfBgLight;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.gold400.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderAccent),
                    ),
                    child: const Center(
                      child: Icon(Icons.architecture,
                          color: AppColors.gold300, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text('أهلاً بك 👋',
                    style: AppTextStyles.display2xl.copyWith(color: textPrimary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('سجّل دخولك للمتابعة',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),

                AppTextField(
                  label: 'البريد الإلكتروني أو رقم الهاتف',
                  hint: 'example@mail.com أو 05XXXXXXXX',
                  controller: _emailCtrl,
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
                    if (v.contains('@')) return AuthFormValidators.validateEmail(v);
                    return AuthFormValidators.validatePhone(v);
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                if (!_isPhone)
                  AppTextField(
                    label: 'كلمة المرور',
                    hint: '••••••••',
                    obscureText: true,
                    controller: _passCtrl,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => _isPhone ? null : AuthFormValidators.validatePassword(v),
                  ),

                const SizedBox(height: 10),
                if (!_isPhone)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRouter.forgot),
                      child: Text('نسيت كلمة المرور؟',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.gold400)),
                    ),
                  ),

                const SizedBox(height: 16),
                PrimaryButton(
                  label: _isPhone ? 'إرسال رمز التحقق' : 'دخول',
                  loading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () async {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState?.validate() ?? false) {
                      final input = _emailCtrl.text.trim();
                      try {
                        if (input.contains('@')) {
                          await ref.read(authProvider.notifier).signIn(
                            email: input,
                            password: _passCtrl.text,
                          );
                        } else {
                          final phoneE164 = AuthFormValidators.toE164(input);
                          final vid = await ref
                              .read(authProvider.notifier)
                              .startPhoneSignIn(phoneNumberE164: phoneE164);
                          
                          if (vid.isNotEmpty && mounted) {
                            Navigator.pushNamed(context, AppRouter.otp, arguments: {
                              'target': phoneE164,
                              'verificationId': vid,
                            });
                          }
                        }
                        
                        // FIX: Imperative navigation after success
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.danger,
                          ));
                        }
                      }
                    }
                  },
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.borderDefault)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('أو',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textTertiary)),
                    ),
                    Expanded(child: Divider(color: AppColors.borderDefault)),
                  ],
                ),
                const SizedBox(height: 24),

                SecondaryButton(
                  label: 'المتابعة بحساب Google',
                  icon: Icons.g_mobiledata,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google Sign-In قريباً')),
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ليس لديك حساب؟',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRouter.signup),
                      child: Text('إنشاء حساب',
                          style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.gold400,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
