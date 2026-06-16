// lib/features/product/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../core/models/product_model.dart';
import '../cart/providers/cart_provider.dart';
import '../favorites/providers/favorites_provider.dart';
import 'providers/product_provider.dart';
import '../../core/constants/app_constants.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedVariantIndex = -1;

  @override
  Widget build(BuildContext context) {
    // (4) Type-safe RouteSettings.arguments parsing
    final args = ModalRoute.of(context)?.settings.arguments;
    final ProductModel? passedProduct = args is ProductModel ? args : null;

    if (passedProduct == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorStateWidget(message: 'تعذر العثور على بيانات المنتج'),
      );
    }

    // (1) Using .when for AsyncValue handling
    final productsAsync = ref.watch(productsStreamProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider);

    return productsAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, st) => Scaffold(
        body: ErrorStateWidget(
          message: 'فشل تحميل بيانات المنتج المحدثة',
          onRetry: () => ref.refresh(productsStreamProvider),
        ),
      ),
      data: (products) {
        // Find the live version of the passed product to ensure stock is fresh
        final product = products.firstWhere(
          (p) => p.id == passedProduct.id,
          orElse: () => passedProduct,
        );

        final colorScheme = Theme.of(context).colorScheme;
        final isFavorite = favoriteIds.contains(product.id);
        final hasVariants = product.productVariants.isNotEmpty;
        final variantSelected = _selectedVariantIndex != -1;
        
        final currentStock = (hasVariants && variantSelected) 
            ? product.productVariants[_selectedVariantIndex].stock 
            : product.totalStock;
        
        final inStock = (hasVariants && variantSelected)
            ? product.productVariants[_selectedVariantIndex].isInStock
            : product.isInStock;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                expandedHeight: 320,
                pinned: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios,
                      size: 18,
                      color: colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? colorScheme.secondary : colorScheme.onSurface,
                    ),
                    onPressed: () => ref.read(favoriteIdsProvider.notifier).toggle(product.id),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: colorScheme.surface,
                    child: product.imageUrl == null || product.imageUrl!.isEmpty
                        ? Center(
                            child: Icon(
                              _categoryIcon(product.category),
                              color: colorScheme.primary.withValues(alpha: 0.5),
                              size: 100,
                            ),
                          )
                        : Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colorScheme.primary.withValues(alpha: 0.5),
                                size: 100,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: AppTextStyles.display2xl.copyWith(
                                  color: colorScheme.onSurface),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppConstants.formatEGP(product.finalPrice),
                                style: AppTextStyles.displayXl.copyWith(color: colorScheme.secondary),
                              ),
                              if (product.hasDiscount)
                                Text(
                                  AppConstants.formatEGP(product.price),
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(product.category,
                                style: AppTextStyles.bodySm.copyWith(color: colorScheme.primary)),
                          ),
                          const SizedBox(width: 12),
                          if (!inStock)
                            Text('نفذت الكمية',
                                style: AppTextStyles.bodySm.copyWith(color: colorScheme.error))
                          else if (currentStock <= 5)
                            Text('تبقى $currentStock فقط!',
                                style: AppTextStyles.bodySm.copyWith(color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('الوصف',
                          style: AppTextStyles.displayLg.copyWith(
                              color: colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(product.description,
                          style: AppTextStyles.bodyMd.copyWith(color: colorScheme.onSurfaceVariant, height: 1.7)),
                      if (hasVariants) ...[
                        const SizedBox(height: 24),
                        Text('خيارات المُنْتَج',
                            style: AppTextStyles.displayLg.copyWith(
                                color: colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: product.productVariants.asMap().entries.map((e) {
                            final sel = e.key == _selectedVariantIndex;
                            final variant = e.value;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedVariantIndex = e.key),
                              child: Opacity(
                                opacity: variant.isInStock ? 1.0 : 0.5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: sel ? colorScheme.primary : colorScheme.outlineVariant),
                                  ),
                                  child: Text(variant.name,
                                      style: AppTextStyles.bodyMd.copyWith(
                                          color: sel ? colorScheme.secondary : colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                          decoration: variant.isInStock ? null : TextDecoration.lineThrough)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: inStock ? 'أضف إلى السلة' : 'نفذت الكمية',
                icon: Icons.shopping_bag_outlined,
                onPressed: inStock
                    ? () {
                        if (hasVariants && !variantSelected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى اختيار خيار أولاً'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        final variant = hasVariants ? product.productVariants[_selectedVariantIndex].name : 'default';
                        ref.read(cartProvider.notifier).addItem(product, variant);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تمت إضافة "${product.name}" إلى السلة ✓'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'أقلام ورسم': return Icons.edit_outlined;
      case 'أدوات قياس': return Icons.straighten_outlined;
      case 'دفاتر وأوراق': return Icons.menu_book_outlined;
      case 'لوازم فنية': return Icons.palette_outlined;
      case 'أدوات رقمية': return Icons.devices_outlined;
      default: return Icons.inventory_2_outlined;
    }
  }
}
