// lib/features/addresses/addresses_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/models/address_model.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/address_provider.dart';

class AddressesScreen extends ConsumerWidget {
  final bool selectionMode;

  const AddressesScreen({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesStreamProvider);
    final currentSelected = ref.watch(activeAddressProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark 
          ? AppColors.surfBg 
          : AppColors.surfBgLight,
      appBar: CustomAppBar(
        title: selectionMode ? 'اختر عنوان التوصيل' : 'عناويني',
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
        onPressed: () => _openForm(context, ref, null),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('خطأ في تحميل العناوين: $err', style: TextStyle(color: colorScheme.error))),
        data: (addresses) => addresses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد عناوين محفوظة',
                      style: AppTextStyles.displayMd.copyWith(
                          color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط + لإضافة عنوان جديد',
                      style: AppTextStyles.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final a = addresses[i];
                  final isSelected = currentSelected?.id == a.id;
                  return _AddressTile(
                    address: a,
                    isSelected: isSelected,
                    selectionMode: selectionMode,
                    onSelect: () {
                      ref.read(manualSelectedAddressProvider.notifier).select(a);
                      Navigator.of(context).pop(a);
                    },
                    onEdit: () => _openForm(context, ref, a),
                    onDelete: () => _confirmDelete(context, ref, a, addresses),
                    onSetDefault: () async {
                      if (user == null) return;
                      try {
                        await ref.read(addressRepositoryProvider).setDefaultAddress(
                              user.uid,
                              a.id,
                              addresses.map((e) => e.id).toList(),
                            );
                        ref.read(manualSelectedAddressProvider.notifier).select(a);
                        if (selectionMode && context.mounted) {
                          Navigator.of(context).pop(a);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('خطأ: $e'),
                            backgroundColor: colorScheme.error,
                          ));
                        }
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AddressModel a,
      List<AddressModel> allAddresses) async {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('حذف العنوان',
            style: AppTextStyles.displayMd.copyWith(
                color: colorScheme.onSurface)),
        content: Text('هل تريد حذف "${a.label}"؟',
            style: AppTextStyles.bodyMd.copyWith(
                color: colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(addressRepositoryProvider).deleteAddress(user.uid, a.id);
        // If was default and there are others, next one becomes default
        if (a.isDefault && allAddresses.length > 1) {
          final next = allAddresses.firstWhere((addr) => addr.id != a.id);
          await ref.read(addressRepositoryProvider).setDefaultAddress(
                user.uid,
                next.id,
                allAddresses
                    .where((addr) => addr.id != a.id)
                    .map((e) => e.id)
                    .toList(),
              );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('خطأ في الحذف: $e'),
                backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  void _openForm(BuildContext context, WidgetRef ref, AddressModel? existing) {
    final user = ref.read(currentUserProvider);
    final addresses = ref.read(addressesStreamProvider).value ?? [];
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressForm(
        existing: existing,
        onSave: (a) async {
          try {
            if (existing == null) {
              await ref
                  .read(addressRepositoryProvider)
                  .addAddress(user.uid, a, addresses.isEmpty);
            } else {
              await ref
                  .read(addressRepositoryProvider)
                  .updateAddress(user.uid, a);
            }
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: AppColors.danger),
              );
            }
          }
        },
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.selectionMode,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = selectionMode && isSelected;

    return GestureDetector(
      onTap: selectionMode ? onSelect : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? colorScheme.primary
                : address.isDefault
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant,
            width: (highlight || address.isDefault) ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (highlight || address.isDefault)
                        ? Icons.location_on
                        : Icons.location_on_outlined,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address.label,
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'افتراضي',
                                style: AppTextStyles.bodySm.copyWith(
                                    color: colorScheme.primary, fontSize: 10),
                              ),
                            ),
                          ],
                          if (highlight) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'محدد',
                                style: AppTextStyles.bodySm.copyWith(
                                    color: colorScheme.primary, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address.fullAddress,
                        style: AppTextStyles.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (address.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          address.phone,
                          style: AppTextStyles.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selectionMode)
                  TextButton(
                    onPressed: onSelect,
                    style: TextButton.styleFrom(
                      backgroundColor: highlight
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      highlight ? '✓ محدد' : 'اختر',
                      style: AppTextStyles.bodySm.copyWith(
                        color: highlight ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: onSetDefault,
                    icon: Icon(Icons.star_outline,
                        size: 14, color: colorScheme.primary),
                    label: Text(
                      'تعيين افتراضي',
                      style: AppTextStyles.bodySm
                          .copyWith(color: colorScheme.primary),
                    ),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: colorScheme.onSurfaceVariant, size: 18),
                  onPressed: onEdit,
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: colorScheme.error, size: 18),
                  onPressed: onDelete,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  final AddressModel? existing;
  final ValueChanged<AddressModel> onSave;

  const _AddressForm({this.existing, required this.onSave});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _labelCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final a = widget.existing!;
      _labelCtrl.text = a.label;
      _districtCtrl.text = a.district;
      _neighborhoodCtrl.text = a.neighborhood;
      _streetCtrl.text = a.street;
      _buildingCtrl.text = a.buildingNum;
      _floorCtrl.text = a.floor;
      _apartmentCtrl.text = a.apartmentNum;
      _phoneCtrl.text = a.phone;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _districtCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _streetCtrl.dispose();
    _buildingCtrl.dispose();
    _floorCtrl.dispose();
    _apartmentCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, inset + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDefault : AppColors.borderDefaultLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'إضافة عنوان' : 'تعديل العنوان',
                style: AppTextStyles.displayMd.copyWith(color: primaryColor),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'تسمية العنوان (المنزل، العمل...)',
                hint: 'المنزل',
                controller: _labelCtrl,
                prefixIcon: Icons.label_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: AppTextField(
                    label: 'الحي',
                    hint: 'حي النرجس',
                    controller: _districtCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'المجاورة',
                    hint: 'المجاورة الأولى',
                    controller: _neighborhoodCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              AppTextField(
                label: 'اسم الشارع',
                hint: 'شارع التسعين',
                controller: _streetCtrl,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: AppTextField(
                    label: 'رقم العمارة',
                    hint: '12',
                    controller: _buildingCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'الدور',
                    hint: '3',
                    controller: _floorCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'رقم الشقة',
                    hint: '5',
                    controller: _apartmentCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              AppTextField(
                label: 'رقم الهاتف (للتوصيل)',
                hint: '01XXXXXXXXX',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب للتوصيل';
                  if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(v.trim())) {
                    return 'رقم هاتف غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: widget.existing == null ? 'إضافة' : 'حفظ التغييرات',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onSave(AddressModel(
                      id: widget.existing?.id ?? '',
                      label: _labelCtrl.text.trim(),
                      district: _districtCtrl.text.trim(),
                      neighborhood: _neighborhoodCtrl.text.trim(),
                      street: _streetCtrl.text.trim(),
                      buildingNum: _buildingCtrl.text.trim(),
                      floor: _floorCtrl.text.trim(),
                      apartmentNum: _apartmentCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                      isDefault: widget.existing?.isDefault ?? false,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
