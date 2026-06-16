// lib/features/states/empty_state_example_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/empty_state_widget.dart';

class EmptyStateExampleScreen extends StatelessWidget {
  const EmptyStateExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfBg,
      appBar: const CustomAppBar(title: 'سلتي'),
      body: EmptyStateWidget(
        icon: Icons.shopping_bag_outlined,
        title: 'سلتك فارغة',
        message: 'تصفّح المنتجات وابدأ بإضافة ما يعجبك إلى السلة',
        buttonLabel: 'تسوّق الآن',
        onButtonPressed: () => Navigator.pop(context),
      ),
    );
  }
}
