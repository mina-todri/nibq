// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../core/constants/auth_form_validators.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/auth_toast.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import 'package:nibq/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark 
          ? AppColors.surfBg 
          : AppColors.surfBgLight,
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
                      color: colorScheme.primary.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.architecture,
                        color: colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'أهلاً بك 👋',
                  style: AppTextStyles.display2xl.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'سجّل دخولك للمتابعة',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                AppTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@mail.com',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthFormValidators.validateEmail,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  obscureText: true,
                  controller: _passCtrl,
                  prefixIcon: Icons.lock_outline,
                  validator: AuthFormValidators.validatePassword,
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.forgot),
                    child: Text(
                      'نسيت كلمة المرور؟',
                      style: AppTextStyles.bodySm.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'دخول',
                  loading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          try {
                            await ref
                                .read(authProvider.notifier)
                                .signIn(
                                  email: _emailCtrl.text.trim(),
                                  password: _passCtrl.text,
                                );
                          } catch (e) {
                            if (!context.mounted) return;
                            final msg = e is AuthException 
                                ? e.message 
                                : e.toString().replaceFirst('Exception: ', '');
                            AuthToast.show(
                              context,
                              type: ToastType.error,
                              title: 'خطأ في تسجيل الدخول',
                              message: msg,
                            );
                          }
                        },
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'أو',
                        style: AppTextStyles.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 24),

                SecondaryButton(
                  label: 'المتابعة بحساب Google',
                  icon: Icons.g_mobiledata,
                  onPressed: isLoading ? null : () async {
                    try {
                      await ref.read(authProvider.notifier).signInWithGoogle();
                    } catch (e) {
                      if (!context.mounted) return;
                      final msg = e is AuthException 
                          ? e.message 
                          : e.toString().replaceFirst('Exception: ', '');
                      AuthToast.show(
                        context,
                        type: ToastType.error,
                        title: 'خطأ في تسجيل الدخول',
                        message: msg,
                      );
                    }
                  },
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRouter.signup),
                      child: Text(
                        'إنشاء حساب',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
