// lib/features/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/order_model.dart';
import '../checkout/providers/order_providers.dart';
import '../notifications/providers/notifications_provider.dart';
import '../../features/auth/providers/auth_provider.dart';


class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = _formatDate(order.createdAt);
    final displayId = order.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('تفاصيل الطلب', style: AppTextStyles.displayMd.copyWith(color: colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Order Header with ID and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم الطلب', style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant)),
                  Text('#$displayId', style: AppTextStyles.displayMd.copyWith(color: colorScheme.primary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('تاريخ الطلب', style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant)),
                  Text(date, style: AppTextStyles.bodyMd.copyWith(color: colorScheme.onSurface)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Tracker
          if (order.status != OrderStatus.cancelled)
            _OrderStatusTracker(currentStatus: order.status)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Text('تم إلغاء هذا الطلب', 
                    style: AppTextStyles.bodyMd.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          
          const SizedBox(height: 24),

          // Info Cards Section
          _infoCard(context, 'طريقة الدفع', order.paymentMethod == 'cash' ? 'كاش عند الاستلام' : 'بطاقة بنكية'),
          const SizedBox(height: 12),

          // Products Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المنتجات', style: AppTextStyles.displayMd.copyWith(color: colorScheme.onSurface)),
                const SizedBox(height: 12),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.inventory_2_outlined, color: colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                Text(
                                    '${item.selectedVariant.isNotEmpty && item.selectedVariant != 'default' ? "${item.selectedVariant} • " : ""}الكمية: ${item.quantity}',
                                    style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Text(AppConstants.formatEGP(item.price * item.quantity),
                              style: AppTextStyles.bodyMd.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Total Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                _row(context, 'المجموع الفرعي', AppConstants.formatEGP(order.subtotal)),
                const SizedBox(height: 8),
                _row(
                  context, 
                  'التوصيل', 
                  order.delivery == 0 ? 'مجاناً' : AppConstants.formatEGP(order.delivery),
                ),
                if (order.discount > 0) ...[
                  const SizedBox(height: 8),
                  _row(context, 'الخصم', '- ${AppConstants.formatEGP(order.discount)}', discountColor: true),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: colorScheme.outlineVariant),
                ),
                _row(context, 'الإجمالي', AppConstants.formatEGP(order.total), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Shipping Address
          Text('عنوان التوصيل', style: AppTextStyles.displayMd.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
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
                    Icon(Icons.location_on_outlined, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(order.address.label, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(order.address.fullAddress, style: AppTextStyles.bodySm.copyWith(height: 1.5, color: colorScheme.onSurfaceVariant)),
                if (order.address.phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(order.address.phone, style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                ],
              ],
            ),
          ),

          // Delivery Notes
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('ملاحظات التوصيل', style: AppTextStyles.displayMd.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_alt_outlined, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.note!,
                      style: AppTextStyles.bodySm.copyWith(height: 1.5, color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (order.status == OrderStatus.pending)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: _CancelOrderButton(orderId: order.id),
            ),
          
          const SizedBox(height: 12),
          _SupportActions(order: order),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant)),
          Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false, bool discountColor = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold
                ? AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)
                : AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant)),
        Text(value,
            style: bold
                ? AppTextStyles.displayMd.copyWith(color: colorScheme.secondary)
                : AppTextStyles.bodyMd.copyWith(
                    color: discountColor ? Colors.green : colorScheme.onSurface,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500
                  )),
      ],
    );
  }
}

class _OrderStatusTracker extends StatelessWidget {
  final OrderStatus currentStatus;

  const _OrderStatusTracker({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final steps = [
      ('قيد الانتظار', Icons.schedule),
      ('تم التأكيد', Icons.check_circle_outline),
      ('تم الشحن', Icons.local_shipping_outlined),
      ('تم التوصيل', Icons.inventory_2),
    ];

    int currentIndex = 0;
    switch (currentStatus) {
      case OrderStatus.pending: currentIndex = 0; break;
      case OrderStatus.confirmed: currentIndex = 1; break;
      case OrderStatus.shipped: currentIndex = 2; break;
      case OrderStatus.delivered: currentIndex = 3; break;
      case OrderStatus.cancelled: currentIndex = -1; break;
    }

    final List<Widget> children = [];
    for (int i = 0; i < steps.length; i++) {
      final isCompleted = i <= currentIndex;
      final color = isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.3);

      children.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? color.withValues(alpha: 0.15) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(steps[i].$2, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              steps[i].$1,
              style: AppTextStyles.bodyXs.copyWith(
                color: isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

      if (i < steps.length - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 24),
              color: i < currentIndex ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: children,
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _loading ? null : () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text('إلغاء الطلب', style: TextStyle(color: colorScheme.onSurface)),
              content: Text('هل أنت متأكد من إلغاء هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('نعم، إلغاء الطلب', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (confirm != true || !mounted) return;
          setState(() => _loading = true);
          try {
            await ref.read(orderRepositoryProvider).cancelOrder(widget.orderId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إلغاء الطلب بنجاح')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: colorScheme.error),
              );
            }
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        child: _loading
            ? SizedBox(height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.error))
            : const Text('إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SupportActions extends ConsumerWidget {
  final OrderModel order;
  const _SupportActions({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    return Column(
      children: [
        if (order.status == OrderStatus.delivered && !order.isRated)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _showRatingDialog(context, ref),
                icon: const Icon(Icons.star_outline),
                label: const Text('تقييم الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        if (order.isRated)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text('تقييمك: ${order.rating} / 5', style: AppTextStyles.bodyMd.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (order.ratingComment != null && order.ratingComment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(order.ratingComment!, style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showComplaintDialog(context, ref, user),
            icon: const Icon(Icons.report_problem_outlined, size: 20),
            label: const Text('إرسال شكوى أو ملاحظة بخصوص هذا الطلب'),
          ),
        ),
      ],
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('تقييم الطلب', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('كيف كانت تجربتك مع هذا الطلب؟', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setState(() => rating = index + 1),
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'أضف تعليقك (اختياري)',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(supportRepositoryProvider).submitOrderRating(
                  orderId: order.id,
                  userId: order.userId,
                  rating: rating,
                  comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال تقييمك بنجاح')));
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final colorScheme = Theme.of(context).colorScheme;
    final msgCtrl = TextEditingController();
    String type = 'order';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('إرسال شكوى/ملاحظة', style: TextStyle(color: colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: colorScheme.surface,
                style: TextStyle(color: colorScheme.onSurface),
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'order', child: Text('مشكلة في الطلب')),
                  DropdownMenuItem(value: 'delivery', child: Text('مشكلة في التوصيل')),
                  DropdownMenuItem(value: 'product', child: Text('مشكلة في المنتجات')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (v) => setState(() => type = v!),
                decoration: InputDecoration(
                  labelText: 'نوع الشكوى',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظاتك هنا...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (msgCtrl.text.trim().isEmpty) return;
                await ref.read(supportRepositoryProvider).sendComplaint(
                  userId: user?.uid ?? 'unknown',
                  userName: user?.displayName ?? 'Guest',
                  orderId: order.id,
                  type: type,
                  message: msgCtrl.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال شكواك، سنقوم بمراجعتها قريباً')));
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}
