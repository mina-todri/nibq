// lib/features/admin/add_edit_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/models/product_model.dart';
import '../product/providers/product_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/routing/app_router.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _discountCtrl;

  // Per-variant management: each entry = {name, stock}
  late List<_VariantEntry> _variantEntries;

  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name);
    _priceCtrl =
        TextEditingController(text: widget.product?.price.toString());
    _descCtrl = TextEditingController(text: widget.product?.description);
    _categoryCtrl = TextEditingController(text: widget.product?.category);
    _discountCtrl = TextEditingController(
        text: (widget.product?.discount ?? 0).toString());

    // Initialise variant entries from existing product or empty
    _variantEntries = (widget.product?.variants ?? [])
        .map((v) => _VariantEntry(
      nameCtrl: TextEditingController(text: v.name),
      stockCtrl:
      TextEditingController(text: v.stock.toString()),
    ))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _discountCtrl.dispose();
    for (final e in _variantEntries) {
      e.nameCtrl.dispose();
      e.stockCtrl.dispose();
    }
    super.dispose();
  }

  void _addVariantEntry() {
    setState(() {
      _variantEntries.add(_VariantEntry(
        nameCtrl: TextEditingController(),
        stockCtrl: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeVariantEntry(int index) {
    final entry = _variantEntries[index];
    entry.nameCtrl.dispose();
    entry.stockCtrl.dispose();
    setState(() => _variantEntries.removeAt(index));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final sizeInMb = file.lengthSync() / (1024 * 1024);
      if (sizeInMb > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                Text('حجم الصورة كبير جداً (الحد الأقصى 5 ميجابايت)'),
                backgroundColor: AppColors.danger),
          );
        }
        return;
      }
      setState(() => _imageFile = file);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate variant names are not empty
    for (final entry in _variantEntries) {
      if (entry.nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يرجى ملء اسم جميع الخيارات أو حذف الفارغة'),
              backgroundColor: AppColors.danger),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final variants = _variantEntries
          .map((e) => ProductVariant(
        name: e.nameCtrl.text.trim(),
        stock: int.tryParse(e.stockCtrl.text.trim()) ?? 0,
      ))
          .toList();

      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        imageUrl: widget.product?.imageUrl,
        rating: widget.product?.rating ?? 4.5,
        reviewCount: widget.product?.reviewCount ?? 10,
        discount: double.tryParse(_discountCtrl.text.trim()),
        variants: variants,
      );

      if (widget.product == null) {
        await ref.read(productServiceProvider).addProduct(product, _imageFile);
      } else {
        await ref
            .read(productServiceProvider)
            .updateProduct(product, _imageFile);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('Cloudinary')
              ? 'فشل رفع الصورة للمتجر'
              : 'فشل حفظ المنتج: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('عذراً، غير مسموح لك بالدخول لهذه الصفحة'),
              backgroundColor: AppColors.danger),
        );
        AppRouter.navigateToHome(context);
      });
      return const Scaffold();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: CustomAppBar(
          title: widget.product == null ? 'إضافة منتج' : 'تعديل منتج'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(color: AppColors.gold400),
                const SizedBox(height: 20),
              ],

              // Image picker
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfRaised
                        : AppColors.surfRaisedLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                      Image.file(_imageFile!, fit: BoxFit.cover))
                      : (widget.product?.imageUrl != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(widget.product!.imageUrl!,
                          fit: BoxFit.cover))
                      : const Icon(Icons.add_a_photo_outlined, size: 40)),
                ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                label: 'اسم المنتج',
                hint: 'مثال: طقم أقلام رصاص',
                controller: _nameCtrl,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'السعر (EGP)',
                      hint: '100',
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'الخصم (%)',
                      hint: '0',
                      controller: _discountCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'الفئة',
                hint: 'أقلام ورسم',
                controller: _categoryCtrl,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'الوصف',
                hint: 'وصف مفصل للمنتج...',
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),

              // ── Variants with individual stock ──────────────────────
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الخيارات والمخزون',
                    style: AppTextStyles.displayLg.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight),
                  ),
                  TextButton.icon(
                    onPressed: _addVariantEntry,
                    icon: const Icon(Icons.add, color: AppColors.gold400),
                    label: Text('إضافة خيار',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.gold400)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_variantEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfRaised
                        : AppColors.surfRaisedLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.borderSubtle,
                        style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.textTertiary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لم تُضف أي خيارات. اضغط "إضافة خيار" لإضافة الخيارات مع مخزونها.',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._variantEntries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _VariantRow(
                      index: idx,
                      entry: e,
                      isDark: isDark,
                      onRemove: () => _removeVariantEntry(idx),
                    ),
                  );
                }),

              const SizedBox(height: 30),
              PrimaryButton(
                label: widget.product == null ? 'إضافة المنتج' : 'حفظ التعديلات',
                onPressed: _isLoading ? null : _save,
                loading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantEntry {
  final TextEditingController nameCtrl;
  final TextEditingController stockCtrl;
  _VariantEntry({required this.nameCtrl, required this.stockCtrl});
}

class _VariantRow extends StatelessWidget {
  final int index;
  final _VariantEntry entry;
  final bool isDark;
  final VoidCallback onRemove;

  const _VariantRow({
    required this.index,
    required this.entry,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Variant number badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold400.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.gold300, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),

          // Name field
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: entry.nameCtrl,
              decoration: InputDecoration(
                labelText: 'اسم الخيار',
                hintText: 'مثال: A4',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Stock field
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.stockCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الكمية',
                hintText: '0',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 20),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}