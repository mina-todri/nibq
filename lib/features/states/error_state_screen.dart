// lib/features/states/error_state_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/error_state_widget.dart';

class ErrorStateScreen extends StatelessWidget {
  const ErrorStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfBg,
      appBar: const CustomAppBar(title: 'خطأ'),
      body: ErrorStateWidget(
        title: 'لا يوجد اتصال بالإنترنت',
        message: 'تأكد من الاتصال وحاول مجدداً',
        onRetry: () {},
      ),
    );
  }
}
