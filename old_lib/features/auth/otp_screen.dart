// lib/features/auth/otp_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/otp_input_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String? verificationId;
  const OtpScreen({super.key, this.verificationId});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  int _secondsLeft = 60;
  Timer? _timer;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _secondsLeft = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resendCode() {
    _startTimer();
    // TODO: Wire up to ref.read(authProvider.notifier).startPhoneSignIn again if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إعادة إرسال الرمز'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _verifyOtp(String vid) async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رمز التحقق كاملاً'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      // TODO: Implementation uses FirebaseAuth.verifyPhoneNumber internally in AuthService
      // which produces a verificationId. confirmPhoneOtp calls signInWithCredential
      // using PhoneAuthProvider.credential(verificationId: vid, smsCode: _otpCode).
      await ref.read(authProvider.notifier).confirmPhoneOtp(
            verificationId: vid,
            smsCode: _otpCode,
          );
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

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    String target = args?['target'] ?? '05XXXXXXXX';
    String verificationId = args?['verificationId'] ?? widget.verificationId ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfBg,
      appBar: const CustomAppBar(title: 'التحقق'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('أدخل رمز التحقق', style: AppTextStyles.display2xl),
            const SizedBox(height: 12),
            Text(
              'أرسلنا رمزاً مكوناً من 6 أرقام إلى $target',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            OtpInputField(
              length: 6,
              onCompleted: (code) {
                setState(() => _otpCode = code);
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'لم يصلك الرمز؟',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _secondsLeft > 0 ? null : _resendCode,
                    child: Text(
                      _secondsLeft > 0
                          ? 'إعادة الإرسال ($_secondsLeft)'
                          : 'إعادة الإرسال',
                      style: AppTextStyles.bodySm.copyWith(
                        color: _secondsLeft > 0
                            ? AppColors.textTertiary
                            : AppColors.gold300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'تأكيد',
              loading: isLoading,
              onPressed: isLoading ? null : () => _verifyOtp(verificationId),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
