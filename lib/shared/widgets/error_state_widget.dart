// lib/shared/widgets/error_state_widget.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import 'primary_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.title = 'حدث خطأ ما',
    this.message = 'يرجى المحاولة مرة أخرى',
    this.onRetry,
    this.icon = Icons.error_outline,
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
                color: colorScheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.error,
              ),
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
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: 'إعادة المحاولة', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
