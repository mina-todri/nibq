// lib/shared/widgets/secondary_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_radius.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTextStyles.buttonLg.copyWith(color: colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
