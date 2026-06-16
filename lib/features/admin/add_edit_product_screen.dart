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

class VariantFieldGroup {
  final TextEditingController nameCtrl;
  final TextEditingController stockCtrl;
  VariantFieldGroup({String? name, int? stock})
      : nameCtrl = TextEditingController(text: name),
        stockCtrl = TextEditingController(text: stock?.toString() ?? '0');
  
  void dispose() {
    nameCtrl.dispose();
    stockCtrl.dispose();
  }
}

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _baseStockCtrl; // Used only if no variants
  
  final List<VariantFieldGroup> _variantFields = [];
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name);
    _priceCtrl = TextEditingController(text: widget.product?.price.toString());
    _descCtrl = TextEditingController(text: widget.product?.description);
    _categoryCtrl = TextEditingController(text: widget.product?.category);
    _discountCtrl = TextEditingController(text: (widget.product?.discount ?? 0).toString());
    _baseStockCtrl = TextEditingController(text: (widget.product?.totalStock ?? 0).toString());

    if (widget.product?.productVariants != null) {
      for (final v in widget.product!.productVariants) {
        _variantFields.add(VariantFieldGroup(name: v.name, stock: v.stock));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _discountCtrl.dispose();
    _baseStockCtrl.dispose();
    for (final f in _variantFields) {
      f.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() {
      _variantFields.add(VariantFieldGroup());
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variantFields[index].dispose();
      _variantFields.removeAt(index);
    });
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
            const SnackBar(content: Text('حجم الصورة كبير جداً (الحد الأقصى 5 ميجابايت)'), backgroundColor: AppColors.danger),
          );
        }
        return;
      }
      setState(() => _imageFile = file);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productVariants = _variantFields.map((f) => ProductVariant(
        name: f.nameCtrl.text.trim(),
        stock: int.tryParse(f.stockCtrl.text.trim()) ?? 0,
      )).where((v) => v.name.isNotEmpty).toList();

      int totalStock;
      if (productVariants.isEmpty) {
        totalStock = int.tryParse(_baseStockCtrl.text.trim()) ?? 0;
      } else {
        totalStock = productVariants.fold(0, (sum, v) => sum + v.stock);
      }

      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        imageUrl: widget.product?.imageUrl,
        rating: widget.product?.rating ?? 4.5,
        reviewCount: widget.product?.reviewCount ?? 10,
        totalStock: totalStock,
        discount: double.tryParse(_discountCtrl.text.trim()),
        productVariants: productVariants,
      );

      if (widget.product == null) {
        await ref.read(productServiceProvider).addProduct(product, _imageFile);
      } else {
        await ref.read(productServiceProvider).updateProduct(product, _imageFile);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('Cloudinary') ? 'فشل رفع الصورة للمتجر' : 'فشل حفظ المنتج: $e'),
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
          const SnackBar(content: Text('عذراً، غير مسموح لك بالدخول لهذه الصفحة'), backgroundColor: AppColors.danger),
        );
        AppRouter.navigateToHome(context);
      });
      return const Scaffold();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: CustomAppBar(title: widget.product == null ? 'إضافة منتج' : 'تعديل منتج'),
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
              _buildImagePicker(isDark),
              const SizedBox(height: 20),
              AppTextField(
                label: 'اسم المنتج',
                hint: 'مثال: طقم أقلام رصاص',
                controller: _nameCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
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
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
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
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),
              _buildVariantsSection(isDark),
              const SizedBox(height: 24),
              AppTextField(
                label: 'الوصف',
                hint: 'وصف مفصل للمنتج...',
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                label: widget.product == null ? 'إضافة المنتج' : 'حفظ التعديلات',
                onPressed: _isLoading ? null : _save,
                loading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
        ),
        child: _imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.cover))
            : (widget.product?.imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.product!.imageUrl!, fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.gold400),
                      const SizedBox(height: 8),
                      Text('أضف صورة المنتج', style: AppTextStyles.bodySm.copyWith(color: secondaryColor)),
                    ],
                  )),
      ),
    );
  }

  Widget _buildVariantsSection(bool isDark) {
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الخيارات والمخزون',
              style: AppTextStyles.displayMd.copyWith(color: primaryColor),
            ),
            TextButton.icon(
              onPressed: _addVariant,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة خيار'),
              style: TextButton.styleFrom(foregroundColor: AppColors.gold400),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_variantFields.isEmpty)
          AppTextField(
            label: 'الكمية الإجمالية (لا توجد خيارات)',
            hint: '50',
            controller: _baseStockCtrl,
            keyboardType: TextInputType.number,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variantFields.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final field = _variantFields[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'اسم الخيار',
                        hint: 'A3, أحمر...',
                        controller: field.nameCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: AppTextField(
                        label: 'الكمية',
                        hint: '10',
                        controller: field.stockCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeVariant(index),
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
