// lib/features/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/auth_form_validators.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final email = _emailCtrl.text.trim();
      await ref.read(authProvider.notifier).resetPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رابط استعادة كلمة السر لبريدك الإلكتروني'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
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
      appBar: const CustomAppBar(title: 'استعادة كلمة السر'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'نسيت كلمة السر؟',
                style: AppTextStyles.display2xl.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لاستعادة الوصول لحسابك',
                style: AppTextStyles.bodyMd.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'البريد الإلكتروني',
                hint: 'name@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: AuthFormValidators.validateEmail,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'إرسال الرابط',
                loading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
