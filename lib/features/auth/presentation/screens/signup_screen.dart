import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/constants/auth_form_validators.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Listener ──────────────────────────────────────────────────────────────

  void _handleStateChange(AuthState? prev, AuthState next) {
    if (next is AuthAuthenticated) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
    }
    if (next is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.message), backgroundColor: Colors.red),
      );
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authProvider.notifier)
        .register(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, _handleStateChange);

    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'إنشاء حساب جديد',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل بياناتك للبدء',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Display name
                AuthTextField(
                  label: 'الاسم',
                  hint: 'الاسم الكامل',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: AuthFormValidators.validateDisplayName,
                ),
                const SizedBox(height: 16),

                // Email
                AuthTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@mail.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: AuthFormValidators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Password
                AuthTextField(
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  controller: _passCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: AuthFormValidators.validatePassword,
                ),
                const SizedBox(height: 16),

                // Confirm password
                AuthTextField(
                  label: 'تأكيد كلمة المرور',
                  hint: '••••••••',
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  // Cross-field validation: reads _passCtrl directly.
                  validator: (v) => AuthFormValidators.validateConfirmPassword(
                    v,
                    _passCtrl.text,
                  ),
                ),
                const SizedBox(height: 28),

                // Signup button
                AuthButton(
                  label: 'إنشاء حساب',
                  loading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب بالفعل؟'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تسجيل الدخول'),
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
