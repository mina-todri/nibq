// lib/features/checkout/order_success_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import 'providers/order_providers.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final orderId = args is String && args.isNotEmpty ? args : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final surfColor = isDark ? AppColors.surfBg : AppColors.surfBgLight;

    if (orderId == null) {
      return Scaffold(
        backgroundColor: surfColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تعذر تحميل الطلب',
                    style: AppTextStyles.displayLg.copyWith(color: primaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    label: 'العودة للرئيسية',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.home,
                      (_) => false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final orderAsync = ref.watch(orderByIdProvider(orderId));

    // (2) WRAP with PopScope to prevent back button from going to checkout
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: surfColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: orderAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold400)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تعذر تحميل الطلب',
                      style: AppTextStyles.displayLg.copyWith(color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: AppTextStyles.bodySm.copyWith(color: secondaryColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      label: 'العودة للرئيسية',
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.home,
                        (_) => false,
                      ),
                    ),
                  ],
                ),
              ),
              data: (order) {
                return Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        color: AppColors.gold400.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold400.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: isDark ? AppColors.gold300 : AppColors.gold400,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'تم تأكيد طلبك!',
                      style: AppTextStyles.display2xl.copyWith(
                        color: isDark ? AppColors.gold300 : AppColors.gold400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'عدد المنتجات: ${order.items.fold<int>(0, (s, i) => s + i.quantity)} • الإجمالي: ${AppConstants.formatEGP(order.total)}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: secondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: isDark ? AppColors.borderDefault : AppColors.borderDefaultLight),
                      ),
                      child: Text(
                        'رقم الطلب #${order.id}',
                        style: AppTextStyles.bodySm.copyWith(color: primaryColor),
                      ),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'تصفح طلباتي',
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.profile,
                        (_) => false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'العودة للرئيسية',
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.home,
                        (_) => false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
