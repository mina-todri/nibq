// lib/features/admin/admin_inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../core/models/product_model.dart';
import '../../core/constants/app_constants.dart';
import '../product/providers/product_provider.dart';
import 'add_edit_product_screen.dart';

class AdminInventoryScreen extends ConsumerWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'إدارة المخزون'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold400,
        tooltip: 'إضافة منتج',
        child: const Icon(Icons.add, color: AppColors.textInverse),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('لا توجد منتجات',
                      style: AppTextStyles.displayMd.copyWith(
                        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      )),
                  const SizedBox(height: 8),
                  Text('اضغط + لإضافة منتج',
                      style: AppTextStyles.bodySm.copyWith(
                        color: isDark ? AppColors.textTertiary : AppColors.textTertiaryLight,
                      )),
                ],
              ),
            );
          }

          final outOfStock = products.where((p) => p.totalStock == 0).length;
          final lowStock =
              products.where((p) => p.totalStock > 0 && p.totalStock <= 5).length;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    _StatChip(
                        label: 'إجمالي',
                        count: products.length,
                        color: AppColors.info),
                    const SizedBox(width: 12),
                    _StatChip(
                        label: 'منخفض',
                        count: lowStock,
                        color: AppColors.warning),
                    const SizedBox(width: 12),
                    _StatChip(
                        label: 'نفد',
                        count: outOfStock,
                        color: AppColors.danger),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _InventoryTile(
                    product: products[i],
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold400)),
        error: (e, _) => Center(
            child: Text('خطأ في تحميل المنتجات: $e',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.danger))),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTextStyles.displayMd
                  .copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            Text(label,
                style:
                    AppTextStyles.bodySm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  final ProductModel product;
  final bool isDark;
  const _InventoryTile({required this.product, required this.isDark});

  Color get _stockColor {
    if (product.totalStock == 0) return AppColors.danger;
    if (product.totalStock <= 5) return AppColors.warning;
    return AppColors.success;
  }

  String get _stockLabel {
    if (product.totalStock == 0) return 'نفد المخزون';
    if (product.totalStock <= 5) return 'مخزون منخفض';
    return 'متوفر';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.totalStock == 0
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surfOverlay,
              image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.imageUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                ? const Icon(Icons.image_outlined,
                    color: AppColors.textTertiary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.formatEGP(product.finalPrice),
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.gold400),
                ),
                if (product.hasDiscount)
                  Text(
                    AppConstants.formatEGP(product.price),
                    style: AppTextStyles.bodySm.copyWith(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _stockColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _stockLabel,
                      style: AppTextStyles.bodySm
                          .copyWith(color: _stockColor, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product.totalStock} قطعة',
                    style: AppTextStyles.bodySm.copyWith(
                      color: _stockColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StockBtn(
                    icon: Icons.remove,
                    color: AppColors.danger,
                    onTap: product.totalStock > 0
                        ? () => _updateStock(context, ref, product, -1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${product.totalStock}',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _stockColor,
                      ),
                    ),
                  ),
                  _StockBtn(
                    icon: Icons.add,
                    color: AppColors.success,
                    onTap: () => _updateStock(context, ref, product, 1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.gold400, size: 18),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddEditProductScreen(product: product)),
                    ),
                    tooltip: 'تعديل',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 18),
                    onPressed: () => _confirmDelete(context, ref, product),
                    tooltip: 'حذف',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStock(
      BuildContext context, WidgetRef ref, ProductModel product, int delta) async {
    String? selectedVariant;

    // If product has variants, ask which one to update
    if (product.productVariants.isNotEmpty) {
      selectedVariant = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(delta > 0 ? 'زيادة مخزون خيار' : 'نقص مخزون خيار', 
                style: AppTextStyles.displayMd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: product.productVariants.map((v) {
              return ListTile(
                title: Text(v.name),
                subtitle: Text('المخزون الحالي: ${v.stock}'),
                onTap: () => Navigator.pop(context, v.name),
              );
            }).toList(),
          ),
        ),
      );

      if (selectedVariant == null) return; // User cancelled
    }

    try {
      await ref.read(productServiceProvider).updateProductStock(
        productId: product.id,
        delta: delta,
        variantName: selectedVariant,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ProductModel product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل تريد حذف "${product.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(productServiceProvider).deleteProduct(product.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    }
  }
}

class _StockBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StockBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: (onTap != null ? color : Colors.grey)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? color : Colors.grey),
      ),
    );
  }
}
