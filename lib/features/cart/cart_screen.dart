// lib/features/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/price_summary_row.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../core/models/cart_item_model.dart';
import 'providers/cart_provider.dart';
import '../../core/constants/app_constants.dart';
import '../settings/providers/global_settings_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final settingsAsync = ref.watch(globalSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark 
          ? AppColors.surfBg 
          : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'سلة الشراء'),
      body: settingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => ErrorStateWidget(
          message: 'فشل تحميل إعدادات التوصيل',
          onRetry: () => ref.refresh(globalSettingsProvider),
        ),
        data: (settings) {

          if (cartItems.isEmpty) {
            return const EmptyStateWidget(
              title: 'السلة فارغة',
              message: 'ابدأ بإضافة أدواتك المفضلة للمتابعة',
              icon: Icons.shopping_cart_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: cartItems.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CartItemView(item: cartItems[i]),
          );
        },
      ),
      bottomNavigationBar: cartItems.isEmpty
          ? const SizedBox.shrink()
          : settingsAsync.maybeWhen(
              data: (settings) => Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: colorScheme.brightness == Brightness.dark ? AppColors.surfBase : AppColors.surfBaseLight,
                  border: Border(
                      top: BorderSide(
                          color: colorScheme.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriceSummaryRow(
                          label: 'المجموع الفرعي',
                          value: AppConstants.formatEGP(subtotal)),
                      const SizedBox(height: 6),
                      PriceSummaryRow(
                          label: 'التوصيل',
                          value: settings.freeDelivery
                              ? 'مجاناً'
                              : AppConstants.formatEGP(settings.deliveryFee)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                            color: colorScheme.outlineVariant),
                      ),
                      PriceSummaryRow(
                          label: 'الإجمالي',
                          value: AppConstants.formatEGP(subtotal + (settings.freeDelivery ? 0.0 : settings.deliveryFee)),                          isBold: true),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'متابعة الدفع',
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRouter.checkout),
                      ),
                    ],
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
    );
  }
}
class _CartItemView extends ConsumerWidget {
  final CartItem item;
  const _CartItemView({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key('${item.product.id}_${item.selectedVariant}'),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      onDismissed: (_) => ref
          .read(cartProvider.notifier)
          .removeItem(item.product.id, item.selectedVariant),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                image: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(item.product.imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: item.product.imageUrl == null || item.product.imageUrl!.isEmpty
                  ? Icon(Icons.inventory_2_outlined, color: colorScheme.onSurfaceVariant.withValues(alpha:0.5), size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (item.selectedVariant.isNotEmpty && item.selectedVariant != 'default') ...[
                    const SizedBox(height: 2),
                    Text('الخيار: ${item.selectedVariant}',
                        style: AppTextStyles.bodySm
                            .copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 6),
                  Text(AppConstants.formatEGP(item.product.finalPrice),
                      style: AppTextStyles.displayMd
                          .copyWith(color: colorScheme.primary)),
                ],
              ),
            ),
            _QuantityControl(item: item),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends ConsumerWidget {
  final CartItem item;
  const _QuantityControl({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.brightness == Brightness.dark ? AppColors.surfBase : AppColors.surfOverlayLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: colorScheme.outline),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => ref.read(cartProvider.notifier).updateQuantity(
                item.product.id, item.selectedVariant, item.quantity - 1),
            icon: Icon(Icons.remove, size: 16, color: colorScheme.onSurface),
            constraints: const BoxConstraints(minWidth: 34),
            padding: EdgeInsets.zero,
          ),
          Text('${item.quantity}',
              style: AppTextStyles.bodyMd.copyWith(
                  color: colorScheme.onSurface)),
          IconButton(
            onPressed: () => ref.read(cartProvider.notifier).updateQuantity(
                item.product.id, item.selectedVariant, item.quantity + 1),
            icon: Icon(Icons.add, size: 16, color: colorScheme.primary),
            constraints: const BoxConstraints(minWidth: 34),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
