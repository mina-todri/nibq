// lib/shared/widgets/price_summary_row.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PriceSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const PriceSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isBold
                ? AppTextStyles.displayMd
                : AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: isBold
              ? AppTextStyles.displayLg.copyWith(color: AppColors.gold300)
              : AppTextStyles.bodyMd,
        ),
      ],
    );
  }
}
