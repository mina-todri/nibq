// lib/features/admin/admin_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../core/models/order_model.dart';
import '../../core/constants/app_constants.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/routing/app_router.dart';
import '../checkout/providers/order_providers.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose(){
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // Route Protection
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عذراً، غير مسموح لك بالدخول لهذه الصفحة'),
            backgroundColor: AppColors.danger,
          ),
        );
        AppRouter.navigateToHome(context);
      });
      return const Scaffold();
    }

    final ordersAsync = ref.watch(allOrdersProvider);
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
        appBar: CustomAppBar(
          title: 'إدارة الطلبات',
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderSubtle
                      : AppColors.borderSubtleLight,
                ),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  color: AppColors.gold400,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: const [
                  _FancyTab(text: 'الكل', icon: Icons.dashboard_outlined),
                  _FancyTab(text: 'قيد الانتظار', icon: Icons.schedule),
                  _FancyTab(text: 'تم التأكيد', icon: Icons.verified_outlined),
                  _FancyTab(text: 'تم الشحن', icon: Icons.local_shipping_outlined),
                  _FancyTab(text: 'تم التوصيل', icon: Icons.check_circle_outline),
                  _FancyTab(text: 'ملغي', icon: Icons.cancel_outlined),
                ],
              ),
            ),
          ),
        ),
        body: ordersAsync.when(
          data: (orders) {
            final searchQuery = _searchController.text.trim().toLowerCase();
            final filteredOrders = orders.where((order) {
              if (searchQuery.isEmpty) return true;
              return order.userName.toLowerCase().contains(searchQuery) ||
                  order.address.phone.contains(searchQuery) ||
                  order.id.toLowerCase().contains(searchQuery);
            }).toList();
            return Column(
                children: [
            Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
            hintText: 'البحث بالاسم، رقم الهاتف، أو رقم الطلب...',
            prefixIcon: const Icon(Icons.search, color: AppColors.gold400),
            suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
            _searchController.clear();
            setState(() {});
            },
            )
                : null,
            filled: true,
            fillColor: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            ),
            ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _OrderList(orders: filteredOrders),
                        _OrderList(orders: filteredOrders.where((o) =>
                        o.status == OrderStatus.pending).toList()),
                        _OrderList(orders: filteredOrders.where((o) =>
                        o.status == OrderStatus.confirmed).toList()),
                        _OrderList(orders: filteredOrders.where((o) =>
                        o.status == OrderStatus.shipped).toList()),
                        _OrderList(orders: filteredOrders.where((o) =>
                        o.status == OrderStatus.delivered).toList()),
                        _OrderList(orders: filteredOrders.where((o) =>
                        o.status == OrderStatus.cancelled).toList()),
                      ],
                    ),
                  ),
            ],
            );
          }
          ,
          loading: () => const LoadingWidget(),
          error: (e, s) =>
              ErrorStateWidget(
                message: 'فشل تحميل الطلبات',
                onRetry: () => ref.refresh(allOrdersProvider),
              ),
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('لا توجد طلبات حالياً',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _OrderTile(order: orders[i]),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final OrderModel order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final displayId = order.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طلب #$displayId',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const Divider(height: 24),
          Text(
            'العميل: ${order.userName}',
            style: AppTextStyles.bodySm.copyWith(color: primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            'الإجمالي: ${AppConstants.formatEGP(order.total)}',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.gold400,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'العنوان: ${order.address.district} - ${order.address.neighborhood}',
            style: AppTextStyles.bodySm.copyWith(color: secondaryColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showOrderDetails(context, ref, order),
                child: const Text('التفاصيل'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold400),
                onPressed: () => _updateStatus(context, ref, order),
                child: const Text('تحديث الحالة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, WidgetRef ref, OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final tertiaryColor = isDark ? AppColors.textTertiary : AppColors.textTertiaryLight;
    final dateStr = DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(order.createdAt);
    final displayId = order.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDefault : AppColors.borderDefaultLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل الطلب #$displayId',
                  style: AppTextStyles.displayLg.copyWith(color: primaryColor),
                ),
                Text(
                  dateStr,
                  style: AppTextStyles.bodySm.copyWith(color: tertiaryColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Customer Section
            Text(
              'بيانات العميل',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.gold400),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfBase : AppColors.surfRaisedLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: secondaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.userName,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone_enabled, size: 20, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.address.phone,
                          style: AppTextStyles.bodyMd.copyWith(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 20, color: secondaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.address.fullAddress,
                          style: AppTextStyles.bodySm.copyWith(color: secondaryColor),
                        ),
                      ),
                    ],
                  ),
                  if (order.note != null && order.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold400.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold400.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note_alt_outlined, size: 18, color: AppColors.gold400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "ملاحظة: ${order.note}",
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.gold400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchWhatsApp(order),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('واتساب'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyForDelivery(context, order),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ للشحن'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items List
            Text(
              'المنتجات',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.gold400),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: order.items.length,
                separatorBuilder: (_, _) => Divider(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
                itemBuilder: (_, i) {
                  final item = order.items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name, style: AppTextStyles.bodyMd.copyWith(color: primaryColor)),
                    subtitle: Text(
                      '${item.selectedVariant} x ${item.quantity}',
                      style: AppTextStyles.bodySm.copyWith(color: secondaryColor),
                    ),
                    trailing: Text(
                      AppConstants.formatEGP(item.price * item.quantity),
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.gold400, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 32),

            // Financial Summary
            _summaryRow(context, 'المجموع الفرعي', AppConstants.formatEGP(order.subtotal)),
            if (order.discount > 0)
              _summaryRow(context, 'خصم إضافي', '- ${AppConstants.formatEGP(order.discount)}', color: AppColors.danger),

            _summaryRow(context, 'التوصيل', order.delivery == 0 ? 'مجاناً' : AppConstants.formatEGP(order.delivery)),
            const SizedBox(height: 8),
            _summaryRow(
              context,
              'الإجمالي النهائي',
              AppConstants.formatEGP(order.total),
              isBold: true,
              fontSize: 18,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value,
      {Color? color, bool isBold = false, double fontSize = 14}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : null,
              color: primaryColor,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              color: color ?? (isBold ? AppColors.gold400 : primaryColor),
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(OrderModel order) async {
    final phone = order.address.phone.replaceAll('+', '').replaceAll(' ', '');
    final displayId = order.id;
    final message = "أهلاً بك يا ${order
        .userName} من متجر Nibq، بخصوص طلبك رقم $displayId...";
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _copyForDelivery(BuildContext context, OrderModel order) {
    final notePart = (order.note != null && order.note!.isNotEmpty)
        ? " | ملاحظات: ${order.note}"
        : "";
    final text = "الاسم: ${order.userName} | "
        "الموبايل: ${order.address.phone} | "
        "العنوان: ${order.address.fullAddress}$notePart | "
        "المطلوب تحصيله: ${AppConstants.formatEGP(order.total)}";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ بيانات الشحن')));
  }

  void _updateStatus(BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تحديث حالة الطلب'),
            if (order.status == OrderStatus.cancelled)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'تنبيه: هذا الطلب ملغي حالياً. تغيير الحالة سيعيد خصم المنتجات من المخزون.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
                ),
              ),
          ],
        ),
        children: OrderStatus.values.map((s) {
          final isSelected = s == order.status;
          return SimpleDialogOption(
            onPressed: isSelected
                ? null
                : () async {
                    if (order.status == OrderStatus.cancelled) {
                      final proceed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('إعادة تفعيل الطلب؟'),
                          content: const Text(
                              'هذا الطلب ملغي. هل أنت متأكد من تغيير حالته؟ سيتم التحقق من توفر المخزون وخصمه مرة أخرى.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('إلغاء')),
                            TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('تأكيد')),
                          ],
                        ),
                      );
                      if (proceed != true) return;
                    }

                    await ref
                        .read(orderRepositoryProvider)
                        .updateOrderStatus(order.id, s);
                    if (context.mounted) Navigator.pop(ctx);
                  },
            child: Row(
              children: [
                Text(
                  _statusText(s),
                  style: TextStyle(
                    color: isSelected ? AppColors.gold400 : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: AppColors.gold400, size: 18),
                ],
              ],
            ),
          );
        }).toList(),
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
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(
          color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _FancyTab extends StatelessWidget {
  final String text;
  final IconData icon;

  const _FancyTab({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}
