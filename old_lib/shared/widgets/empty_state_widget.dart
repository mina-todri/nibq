// lib/shared/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'primary_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.surfRaised,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.ink400),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.displayLg),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: buttonLabel!, onPressed: onButtonPressed),
            ],
          ],
        ),
      ),
    );
  }
}
