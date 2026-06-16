// lib/features/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/price_summary_row.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../cart/providers/cart_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/models/order_model.dart';
import '../../core/models/address_model.dart';
import 'providers/order_providers.dart';
import '../../core/constants/app_constants.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../addresses/providers/address_provider.dart';
import '../addresses/addresses_screen.dart';
import '../settings/providers/global_settings_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isPlacingOrder = false;

  final _discountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  double _appliedDiscountAmount = 0;
  bool _discountApplied = false;
  bool _isValidatingCoupon = false;
  String? _discountError;
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _discountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyDiscount(double subtotal) async {
    final code = _discountCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _discountError = 'أدخل كود الخصم';
        _discountApplied = false;
        _appliedDiscountAmount = 0;
      });
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
      _discountError = null;
    });

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('validateCoupon')
          .call({
        'code': code,
        'subtotal': subtotal,
      });

      final data = result.data as Map<String, dynamic>;
      final bool isValid = data['valid'] ?? false;

      if (!isValid) {
        setState(() {
          _discountError = data['message'] ?? 'كود الخصم غير صحيح';
          _discountApplied = false;
          _appliedDiscountAmount = 0;
        });
        return;
      }

      setState(() {
        _appliedDiscountAmount = (data['discountAmount'] as num?)?.toDouble() ?? 0.0;
        _discountApplied = true;
        _discountError = null;
      });
    } catch (e) {
      setState(() => _discountError = 'حدث خطأ أثناء التحقق من الكود');
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  Future<void> _openAddressPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddressesScreen(selectionMode: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final settingsAsync = ref.watch(globalSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.onSurface;
    final borderColor = colorScheme.outlineVariant;

    return settingsAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, st) => Scaffold(
        body: ErrorStateWidget(
          message: 'فشل تحميل إعدادات الدفع',
          onRetry: () => ref.refresh(globalSettingsProvider),
        ),
      ),
      data: (settings) {
        final delivery = settings.freeDelivery ? 0.0 : settings.deliveryFee;
        final taxable = subtotal - _appliedDiscountAmount;
        final total = taxable + delivery;

        final activeAddress = ref.watch(activeAddressProvider);
        final hasPhone =
            activeAddress != null && activeAddress.phone.isNotEmpty;
        final canPlaceOrder = cartItems.isNotEmpty &&
            !_isPlacingOrder &&
            activeAddress != null &&
            hasPhone;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: const CustomAppBar(title: 'إتمام الشراء'),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('عنوان التوصيل', style: AppTextStyles.displayLg.copyWith(color: primaryColor)),
              const SizedBox(height: 12),
              Consumer(builder: (context, ref, _) {
                final addressesAsync = ref.watch(addressesStreamProvider);
                final activeAddress = ref.watch(activeAddressProvider);

                return addressesAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Text('فشل تحميل العناوين',
                      style: TextStyle(color: colorScheme.error)),
                  data: (addresses) {
                    return _AddressSelectorView(
                        isDark: colorScheme.brightness == Brightness.dark,
                        selectedAddress: activeAddress,
                        onPickerOpen: _openAddressPicker);
                  },
                );
              }),
              Consumer(builder: (context, ref, _) {
                final activeAddress = ref.watch(activeAddressProvider);
                final hasPhone =
                    activeAddress != null && activeAddress.phone.isNotEmpty;

                if (activeAddress != null && !hasPhone) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: colorScheme.error.withValues(alpha:0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.phone_missed,
                            color: colorScheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'العنوان المختار لا يحتوي على رقم هاتف. عدّل العنوان لإضافة رقم الهاتف.',
                            style: AppTextStyles.bodySm
                                .copyWith(color: colorScheme.error),
                          ),
                        ),
                      ]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 24),
              Text('طريقة الدفع', style: AppTextStyles.displayLg.copyWith(color: primaryColor)),
              const SizedBox(height: 12),
              _PaymentMethodSelector(
                isDark: colorScheme.brightness == Brightness.dark,
                currentMethod: _paymentMethod,
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 24),
              Text('ملاحظات التوصيل', style: AppTextStyles.displayLg.copyWith(color: primaryColor)),
              const SizedBox(height: 12),
              AppTextField(
                label: null,
                hint: 'أضف ملاحظات للسائق (اختياري)',
                controller: _noteCtrl,
                maxLines: 2,
              ),
              if (true) ...[
                const SizedBox(height: 24),
                Text('كود الخصم', style: AppTextStyles.displayLg.copyWith(color: primaryColor)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: null,
                        hint: 'أدخل الكود هنا',
                        controller: _discountCtrl,
                        prefixIcon: Icons.discount_outlined,
                        enabled: !_discountApplied && !_isValidatingCoupon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _discountApplied || _isValidatingCoupon
                            ? null
                            : () => _applyDiscount(subtotal),
                        child: _isValidatingCoupon
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _discountApplied ? '✓ مُطبَّق' : 'تطبيق',
                                style: TextStyle(
                                    color: colorScheme.onPrimary),
                              ),
                      ),
                    ),
                  ],
                ),
                if (_discountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_discountError!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: colorScheme.error)),
                  ),
              ],
              const SizedBox(height: 24),
              Text('الملخص', style: AppTextStyles.displayLg.copyWith(color: primaryColor)),
              const SizedBox(height: 12),
              _card(
                isDark: colorScheme.brightness == Brightness.dark,
                child: Column(
                  children: [
                    PriceSummaryRow(
                        label: 'المجموع الفرعي',
                        value: AppConstants.formatEGP(subtotal)),
                    if (_appliedDiscountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: Text('خصم كود الخصم',
                                  style: AppTextStyles.bodyMd
                                      .copyWith(color: AppColors.success))),
                          Text(
                              '- ${AppConstants.formatEGP(_appliedDiscountAmount)}',
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.success)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    PriceSummaryRow(
                      label: 'التوصيل',
                      value: delivery == 0
                          ? 'مجاناً'
                          : AppConstants.formatEGP(delivery),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: borderColor),
                    ),
                    PriceSummaryRow(
                        label: 'الإجمالي',
                        value: AppConstants.formatEGP(total),
                        isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: colorScheme.brightness == Brightness.dark ? AppColors.surfBase : AppColors.surfBaseLight,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              child: PrimaryButton(
                label: 'تأكيد الطلب',
                loading: _isPlacingOrder,
                onPressed: canPlaceOrder ? () => _placeOrder(settings) : null,
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> _placeOrder(GlobalSettings settings) async {
    final user = ref.read(currentUserProvider);
    final cartItems = ref.read(cartProvider);
    final activeAddress = ref.read(activeAddressProvider);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يرجى تسجيل الدخول لإتمام الطلب'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    if (_paymentMethod == 'card') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الدفع بالبطاقة غير متاح حالياً، يرجى اختيار الدفع كاش'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    if (activeAddress == null || activeAddress.phone.isEmpty) return;

    setState(() => _isPlacingOrder = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final subtotal = ref.read(cartTotalProvider);
      final delivery = settings.freeDelivery ? 0.0 : settings.deliveryFee;

      // Use the amount vetted by the server function
      final discountAmount = _discountApplied ? _appliedDiscountAmount : 0.0;

      final total = subtotal - discountAmount + delivery;
      final orderId = AppConstants.generateOrderId();

      final order = OrderModel(
        id: orderId,
        userId: user.uid,
        userName: user.displayName ?? 'عميل',
        items: cartItems
            .map((i) => OrderItemModel(
                  productId: i.product.id,
                  name: i.product.name,
                  category: i.product.category,
                  price: i.product.finalPrice,
                  selectedVariant: i.selectedVariant,
                  quantity: i.quantity,
                ))
            .toList(),
        subtotal: subtotal,
        discount: discountAmount,
        delivery: delivery,
        total: total,
        status: OrderStatus.pending,
        address: activeAddress,
        createdAt: DateTime.now(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        paymentMethod: _paymentMethod,
      );

      await ref.read(orderRepositoryProvider).createOrderWithStockCheck(order);

      await ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(userOrdersProvider);
      ref.invalidate(orderByIdProvider(orderId));

      if (mounted) {
        navigator.pushNamedAndRemoveUntil(
          AppRouter.orderSuccess,
          (route) => route.settings.name == AppRouter.home,
          arguments: orderId,
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('فشل إنشاء الطلب: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  Widget _card({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}

class _AddressSelectorView extends StatelessWidget {
  final bool isDark;
  final AddressModel? selectedAddress;
  final VoidCallback onPickerOpen;

  const _AddressSelectorView(
      {required this.isDark,
      required this.selectedAddress,
      required this.onPickerOpen});

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final tertiaryColor = isDark ? AppColors.textTertiary : AppColors.textTertiaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
      ),
      child: Row(
        children: [
          Icon(
            selectedAddress != null
                ? Icons.location_on
                : Icons.location_off_outlined,
            color:
                selectedAddress != null ? AppColors.gold300 : AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: selectedAddress == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('لا يوجد عنوان',
                          style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger)),
                      Text('يرجى إضافة عنوان توصيل أولاً',
                          style: AppTextStyles.bodySm
                              .copyWith(color: secondaryColor)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(selectedAddress!.label,
                              style: AppTextStyles.bodyMd
                                  .copyWith(fontWeight: FontWeight.w700, color: primaryColor),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.gold400.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('محدد',
                              style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.gold400, fontSize: 10)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(selectedAddress!.fullAddress,
                          style: AppTextStyles.bodySm
                              .copyWith(color: secondaryColor)),
                      if (selectedAddress!.phone.isNotEmpty)
                        Text(selectedAddress!.phone,
                            style: AppTextStyles.bodySm
                                .copyWith(color: tertiaryColor)),
                    ],
                  ),
          ),
          TextButton(
            onPressed: onPickerOpen,
            child: Text(
              selectedAddress == null ? 'إضافة' : 'تغيير',
              style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.gold300 : AppColors.gold400, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final bool isDark;
  final String currentMethod;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodSelector(
      {required this.isDark,
      required this.currentMethod,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text('الدفع عند الاستلام (كاش)', style: TextStyle(color: primaryColor)),
            value: 'cash',
            groupValue: currentMethod,
            onChanged: onChanged,
            activeColor: AppColors.gold400,
          ),
          RadioListTile<String>(
            title: Text('الدفع بالبطاقة (قريباً)', style: TextStyle(color: primaryColor)),
            value: 'card',
            groupValue: currentMethod,
            onChanged: onChanged,
            activeColor: AppColors.gold400,
          ),
        ],
      ),
    );
  }
}
