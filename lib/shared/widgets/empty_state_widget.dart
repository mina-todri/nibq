// lib/shared/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(icon, size: 44, color: colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.displayLg.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: colorScheme.onSurfaceVariant,
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
