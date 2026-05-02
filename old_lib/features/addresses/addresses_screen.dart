// lib/features/addresses/addresses_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/models/address_model.dart';
import '../auth/providers/auth_provider.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class AddressNotifier extends StateNotifier<List<AddressModel>> {
  final String? _uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  AddressNotifier(this._uid) : super([]) {
    if (_uid != null) _listenToAddresses();
  }

  void _listenToAddresses() {
    _sub?.cancel();
    _sub = _db
        .collection('users')
        .doc(_uid)
        .collection('addresses')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs
          .map((doc) => AddressModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> add(AddressModel address) async {
    if (_uid == null) return;
    final shouldBeDefault = state.isEmpty;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('addresses')
        .add({...address.toMap(), 'isDefault': shouldBeDefault});
  }

  Future<void> update(AddressModel address) async {
    if (_uid == null) return;
    if (address.id.isEmpty) throw Exception('معرف العنوان مفقود');
    await _db
        .collection('users')
        .doc(_uid)
        .collection('addresses')
        .doc(address.id)
        .update(address.toMap());
  }

  Future<void> delete(String id) async {
    if (_uid == null) return;
    if (id.isEmpty) throw Exception('معرف العنوان مفقود');
    final wasDefault = state.any((a) => a.id == id && a.isDefault);
    await _db
        .collection('users')
        .doc(_uid)
        .collection('addresses')
        .doc(id)
        .delete();
    if (wasDefault && state.length > 1) {
      final next = state.firstWhere((a) => a.id != id);
      await setDefault(next.id);
    }
  }

  Future<void> setDefault(String id) async {
    if (_uid == null) return;
    final batch = _db.batch();
    final col = _db.collection('users').doc(_uid).collection('addresses');
    for (final a in state) {
      batch.update(col.doc(a.id), {'isDefault': a.id == id});
    }
    await batch.commit();
  }

  AddressModel? get defaultAddress {
    if (state.isEmpty) return null;
    return state.firstWhere(
          (a) => a.isDefault,
      orElse: () => state.first,
    );
  }
}

final addressProvider =
StateNotifierProvider<AddressNotifier, List<AddressModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  return AddressNotifier(user?.uid);
});

// ── Manually-selected address kept in provider state ─────────────────────────

class SelectedAddressNotifier extends StateNotifier<AddressModel?> {
  SelectedAddressNotifier() : super(null);

  void select(AddressModel address) => state = address;
  void clear() => state = null;
}

final selectedAddressNotifierProvider =
StateNotifierProvider<SelectedAddressNotifier, AddressModel?>((ref) {
  return SelectedAddressNotifier();
});

/// The address used at checkout.
/// Priority: manually selected > Firestore default address.
final selectedAddressProvider = Provider<AddressModel?>((ref) {
  final manual = ref.watch(selectedAddressNotifierProvider);
  if (manual != null) return manual;
  return ref.watch(addressProvider.notifier).defaultAddress;
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// When [selectionMode] is true (launched from checkout) each tile shows an
/// "اختر" button. Tapping it writes the address to [selectedAddressNotifierProvider]
/// and pops back to the checkout screen with the [AddressModel] as the result.
class AddressesScreen extends ConsumerWidget {
  final bool selectionMode;

  const AddressesScreen({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider);
    final currentSelected = ref.watch(selectedAddressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: CustomAppBar(
        title: selectionMode ? 'اختر عنوان التوصيل' : 'عناويني',
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold400,
        child: const Icon(Icons.add, color: AppColors.textInverse),
        onPressed: () => _openForm(context, ref, null),
      ),
      body: addresses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'لا توجد عناوين محفوظة',
              style: AppTextStyles.displayMd.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط + لإضافة عنوان جديد',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final a = addresses[i];
          final isSelected = currentSelected?.id == a.id;
          return _AddressTile(
            address: a,
            isSelected: isSelected,
            selectionMode: selectionMode,
            onSelect: () {
              ref
                  .read(selectedAddressNotifierProvider.notifier)
                  .select(a);
              Navigator.of(context).pop(a);
            },
            onEdit: () => _openForm(context, ref, a),
            onDelete: () => _confirmDelete(context, ref, a),
            onSetDefault: () async {
              try {
                await ref
                    .read(addressProvider.notifier)
                    .setDefault(a.id);
                ref
                    .read(selectedAddressNotifierProvider.notifier)
                    .select(a);
                if (selectionMode && context.mounted) {
                  Navigator.of(context).pop(a);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('خطأ: $e'),
                    backgroundColor: AppColors.danger,
                  ));
                }
              }
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AddressModel a) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        title: Text('حذف العنوان',
            style: AppTextStyles.displayMd.copyWith(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight)),
        content: Text('هل تريد حذف "${a.label}"؟',
            style: AppTextStyles.bodyMd.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(addressProvider.notifier).delete(a.id);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressForm(
        existing: existing,
        onSave: (a) async {
          try {
            if (existing == null) {
              await ref.read(addressProvider.notifier).add(a);
            } else {
              await ref.read(addressProvider.notifier).update(a);
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

// ── Address Tile ──────────────────────────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = selectionMode && isSelected;

    return GestureDetector(
      onTap: selectionMode ? onSelect : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? AppColors.gold400
                : address.isDefault
                ? AppColors.gold400.withOpacity(0.5)
                : (isDark
                ? AppColors.borderSubtle
                : AppColors.borderSubtleLight),
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
                    color: (highlight || address.isDefault)
                        ? AppColors.gold400.withOpacity(0.15)
                        : AppColors.gold400.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (highlight || address.isDefault)
                        ? Icons.location_on
                        : Icons.location_on_outlined,
                    color: AppColors.gold400,
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
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
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
                                color: AppColors.gold400
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'افتراضي',
                                style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.gold400, fontSize: 10),
                              ),
                            ),
                          ],
                          if (highlight) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'محدد',
                                style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.success, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address.fullAddress,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      if (address.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          address.phone,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textTertiary),
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
                          ? AppColors.gold400.withOpacity(0.15)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      highlight ? '✓ محدد' : 'اختر',
                      style: AppTextStyles.bodySm.copyWith(
                        color: highlight
                            ? AppColors.gold400
                            : AppColors.gold300,
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
                    icon: const Icon(Icons.star_outline,
                        size: 14, color: AppColors.gold400),
                    label: Text(
                      'تعيين افتراضي',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.gold400),
                    ),
                    style: TextButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: onEdit,
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 18),
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

// ── Address Form ──────────────────────────────────────────────────────────────

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
                    color: AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'إضافة عنوان' : 'تعديل العنوان',
                style: AppTextStyles.displayMd.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight),
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