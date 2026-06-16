// lib/features/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/auth_form_validators.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/auth_toast.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'package:nibq/features/auth/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _agreed = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColors.surfBg
          : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'إنشاء حساب'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أنشئ حسابك',
                style: AppTextStyles.display2xl.copyWith(
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'املأ بياناتك للبدء',
                style: AppTextStyles.bodyMd.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'الاسم الكامل',
                hint: 'محمد أحمد',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline,
                validator: AuthFormValidators.validateDisplayName,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'البريد الإلكتروني',
                hint: 'name@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: AuthFormValidators.validateEmail,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'رقم الهاتف',
                hint: '01XXXXXXXXX',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: AuthFormValidators.validatePhone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'كلمة السر',
                hint: '••••••••',
                obscureText: true,
                controller: _passCtrl,
                prefixIcon: Icons.lock_outline,
                validator: AuthFormValidators.validatePassword,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'تأكيد كلمة السر',
                hint: '••••••••',
                obscureText: true,
                controller: _confirmPassCtrl,
                prefixIcon: Icons.lock_outline,
                validator: (v) =>
                    AuthFormValidators.validateConfirmPassword(
                      v,
                      _passCtrl.text,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppColors.gold400,
                    checkColor: AppColors.textInverse,
                  ),
                  Expanded(
                    child: Text(
                      'أوافق على الشروط والأحكام',
                      style: AppTextStyles.bodySm.copyWith(
                          color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'إنشاء حساب',
                loading: isLoading,
                onPressed: (!_agreed || isLoading)
                    ? null
                    : () async {
                  FocusScope.of(context).unfocus();
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  try {
                    await ref
                        .read(authProvider.notifier)
                        .signUp(
                      email: _emailCtrl.text.trim(),
                      password: _passCtrl.text,
                      confirmPassword: _confirmPassCtrl.text,
                      displayName: _nameCtrl.text.trim(),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      final msg = e is AuthException
                          ? e.message
                          : e.toString().replaceFirst('Exception: ', '');
                      AuthToast.show(
                        context,
                        type: ToastType.error,
                        title: 'خطأ في إنشاء الحساب',
                        message: msg,
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}