// lib/features/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../core/models/order_model.dart';
import '../checkout/providers/order_providers.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'طلباتي'),
      body: ordersAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, st) => ErrorStateWidget(
          message: 'تعذّر تحميل الطلبات',
          onRetry: () => ref.refresh(userOrdersProvider),
        ),
        data: (orders) => orders.isEmpty
            ? const EmptyStateWidget(
                title: 'لا توجد طلبات حتى الآن',
                message: 'ابدأ تسوقك الآن واكتشف أدواتنا المتميزة',
                icon: Icons.shopping_bag_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrderTile(order: orders[i]),
              ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';
    final displayId = order.id;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'طلب #$displayId',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} منتج • $date',
              style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي',
                  style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                ),
                Text(
                  AppConstants.formatEGP(order.total),
                  style: AppTextStyles.displayMd.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'قيد الانتظار';
        break;
      case OrderStatus.confirmed:
        color = Colors.indigo;
        text = 'تم التأكيد';
        break;
      case OrderStatus.shipped:
        color = Colors.blue;
        text = 'تم الشحن';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'تم التوصيل';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'تم الإلغاء';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyXs.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
