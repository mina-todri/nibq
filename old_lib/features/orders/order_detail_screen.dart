// lib/features/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/order_model.dart';
import '../checkout/providers/order_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = _formatDate(order.createdAt);
    final displayId = order.id;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfBase : AppColors.surfBaseLight,
        elevation: 0,
        title: Text('طلب #$displayId', style: AppTextStyles.displayMd),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _infoCard(isDark, 'تاريخ الطلب', date),
          const SizedBox(height: 8),
          _infoCard(isDark, 'حالة الطلب', _statusText(order.status)),
          const SizedBox(height: 8),
          _infoCard(
            isDark,
            'طريقة الدفع',
            order.paymentMethod == 'cash' ? 'كاش' : 'بطاقة',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtle
                    : AppColors.borderSubtleLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المنتجات', style: AppTextStyles.displayMd),
                const SizedBox(height: 12),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppTextStyles.bodyMd),
                              Text(
                                item.formattedVariant,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppConstants.formatEGP(item.price * item.quantity),
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.gold300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtle
                    : AppColors.borderSubtleLight,
              ),
            ),
            child: Column(
              children: [
                _row(
                  isDark,
                  'المجموع الفرعي',
                  AppConstants.formatEGP(order.subtotal),
                ),
                const SizedBox(height: 6),
                _row(
                  isDark,
                  'التوصيل',
                  order.delivery == 0
                      ? 'مجاناً'
                      : AppConstants.formatEGP(order.delivery),
                ),
                if (order.discount > 0) ...[
                  const SizedBox(height: 6),
                  _row(
                    isDark,
                    'الخصم',
                    '- ${AppConstants.formatEGP(order.discount)}',
                    discountColor: true,
                  ),
                ],
                const SizedBox(height: 12),
                _row(
                  isDark,
                  'الإجمالي',
                  AppConstants.formatEGP(order.total),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('عنوان التوصيل', style: AppTextStyles.displayMd),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtle
                    : AppColors.borderSubtleLight,
              ),
            ),
            child: Text(
              order.address.fullAddress,
              style: AppTextStyles.bodySm.copyWith(height: 1.5),
            ),
          ),
          if (order.status == OrderStatus.pending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _CancelOrderButton(orderId: order.id),
            ),
        ],
      ),
    );
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.confirmed:
        return 'تم التأكيد';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.cancelled:
        return 'تم الإلغاء';
    }
  }

  Widget _infoCard(bool isDark, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }

  Widget _row(
    bool isDark,
    String label,
    String value, {
    bool bold = false,
    bool discountColor = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? AppTextStyles.bodyMd
              : AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: bold
              ? AppTextStyles.displayMd.copyWith(color: AppColors.gold300)
              : AppTextStyles.bodyMd.copyWith(
                  color: discountColor ? AppColors.success : null,
                ),
        ),
      ],
    );
  }
}

class _CancelOrderButton extends ConsumerStatefulWidget {
  final String orderId;
  const _CancelOrderButton({required this.orderId});
  @override
  ConsumerState<_CancelOrderButton> createState() => _CancelOrderButtonState();
}

class _CancelOrderButtonState extends ConsumerState<_CancelOrderButton> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _loading
            ? null
            : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('إلغاء الطلب'),
                    content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('لا'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'نعم، إلغاء',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm != true || !mounted) return;
                setState(() => _loading = true);
                try {
                  await ref
                      .read(orderRepositoryProvider)
                      .cancelOrder(widget.orderId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إلغاء الطلب')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        child: _loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.danger,
                ),
              )
            : const Text('إلغاء الطلب'),
      ),
    );
  }
}
