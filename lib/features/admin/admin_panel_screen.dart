// lib/features/admin/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nibq/core/models/product_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../product/providers/product_provider.dart';
import 'add_edit_product_screen.dart';
import '../../core/constants/app_constants.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'إدارة المنتجات'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold400,
        child: const Icon(Icons.add, color: AppColors.textInverse),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
        ),
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? Center(
                child: Text(
                  'لا توجد منتجات',
                  style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: products.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final p = products[i];
                  final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
                  final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

                  return ListTile(
                    tileColor: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isDark ? AppColors.surfOverlay : AppColors.surfOverlayLight,
                        image: p.imageUrl != null && p.imageUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(p.imageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                          ? Icon(Icons.image_outlined, color: secondaryColor)
                          : null,
                    ),
                    title: Text(
                      p.name,
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    subtitle: Text(
                      '${AppConstants.formatEGP(p.price)} • المخزون: ${p.totalStock}',
                      style: AppTextStyles.bodySm.copyWith(color: secondaryColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.gold400),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEditProductScreen(product: p)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, ref, p),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (e, s) => ErrorStateWidget(
          message: 'فشل تحميل المنتجات',
          onRetry: () => ref.refresh(productsStreamProvider),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductModel product) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        title: Text('حذف المنتج', style: AppTextStyles.displayMd.copyWith(color: primaryColor)),
        content: Text('هل أنت متأكد من حذف هذا المنتج؟', style: AppTextStyles.bodyMd.copyWith(color: secondaryColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: AppColors.danger))),
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
