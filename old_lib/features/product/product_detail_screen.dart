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
    final args = ModalRoute.of(context)?.settings.arguments;
    final ProductModel? passedProduct = args is ProductModel ? args : null;

    if (passedProduct == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorStateWidget(message: 'تعذر العثور على بيانات المنتج'),
      );
    }

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
        final product = products.firstWhere(
              (p) => p.id == passedProduct.id,
          orElse: () => passedProduct,
        );

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isFavorite = favoriteIds.contains(product.id);
        final hasVariants = product.variants.isNotEmpty;

        // Determine selected variant and its stock
        final variantSelected = _selectedVariantIndex != -1 &&
            _selectedVariantIndex < product.variants.length;
        final selectedVariant =
        variantSelected ? product.variants[_selectedVariantIndex] : null;

        // Stock logic: if variants exist, base availability on selected variant
        final bool canAdd;
        final String stockLabel;
        final Color? stockColor;

        if (!hasVariants) {
          // No variants — consider out of stock (model now requires variants)
          canAdd = false;
          stockLabel = 'لا توجد خيارات متاحة';
          stockColor = AppColors.danger;
        } else if (!variantSelected) {
          // Variants exist but none selected yet
          canAdd = false;
          stockLabel = product.hasAnyStock ? '' : 'نفذت الكمية من جميع الخيارات';
          stockColor = product.hasAnyStock ? null : AppColors.danger;
        } else {
          // Variant selected — show its stock
          final vStock = selectedVariant!.stock;
          canAdd = vStock > 0;
          if (vStock == 0) {
            stockLabel = 'نفذت كمية هذا الخيار';
            stockColor = AppColors.danger;
          } else if (vStock <= 5) {
            stockLabel = 'تبقى $vStock فقط!';
            stockColor = Colors.orange;
          } else {
            stockLabel = '';
            stockColor = null;
          }
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor:
                isDark ? AppColors.surfBg : AppColors.surfBgLight,
                expandedHeight: 320,
                pinned: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios,
                      size: 18,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppColors.gold300
                          : (isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight),
                    ),
                    onPressed: () => ref
                        .read(favoriteIdsProvider.notifier)
                        .toggle(product.id),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: isDark
                        ? AppColors.surfRaised
                        : AppColors.surfOverlayLight,
                    child: product.imageUrl == null || product.imageUrl!.isEmpty
                        ? Center(
                      child: Icon(
                        _categoryIcon(product.category),
                        color: AppColors.gold400.withOpacity(0.5),
                        size: 100,
                      ),
                    )
                        : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.gold400.withOpacity(0.5),
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
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppConstants.formatEGP(product.finalPrice),
                                style: AppTextStyles.displayXl
                                    .copyWith(color: AppColors.gold300),
                              ),
                              if (product.hasDiscount)
                                Text(
                                  AppConstants.formatEGP(product.price),
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.textTertiary,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold400.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(product.category,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.gold400)),
                          ),
                          const SizedBox(width: 12),
                          if (stockLabel.isNotEmpty)
                            Text(stockLabel,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: stockColor)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('الوصف',
                          style: AppTextStyles.displayLg.copyWith(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight)),
                      const SizedBox(height: 8),
                      Text(product.description,
                          style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.textSecondary, height: 1.7)),
                      if (hasVariants) ...[
                        const SizedBox(height: 24),
                        Text('خيارات المُنْتَج',
                            style: AppTextStyles.displayLg.copyWith(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                          product.variants.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final variant = entry.value;
                            final sel = idx == _selectedVariantIndex;
                            final outOfStock = variant.stock == 0;

                            return GestureDetector(
                              onTap: outOfStock
                                  ? null
                                  : () => setState(
                                      () => _selectedVariantIndex = idx),
                              child: Opacity(
                                opacity: outOfStock ? 0.4 : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.gold400.withOpacity(0.15)
                                        : (isDark
                                        ? AppColors.surfRaised
                                        : AppColors.surfRaisedLight),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: outOfStock
                                            ? AppColors.danger.withOpacity(0.4)
                                            : (sel
                                            ? AppColors.gold400
                                            : (isDark
                                            ? AppColors.borderDefault
                                            : AppColors
                                            .borderDefaultLight))),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        variant.name,
                                        style: AppTextStyles.bodyMd.copyWith(
                                            color: outOfStock
                                                ? AppColors.textTertiary
                                                : (sel
                                                ? AppColors.gold300
                                                : (isDark
                                                ? AppColors.textPrimary
                                                : AppColors
                                                .textPrimaryLight)),
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        outOfStock
                                            ? 'نفذ'
                                            : '${variant.stock} متاح',
                                        style: AppTextStyles.bodySm.copyWith(
                                          fontSize: 10,
                                          color: outOfStock
                                              ? AppColors.danger
                                              : (variant.stock <= 5
                                              ? Colors.orange
                                              : AppColors.success),
                                        ),
                                      ),
                                    ],
                                  ),
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
              color: isDark ? AppColors.surfBase : AppColors.surfBaseLight,
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? AppColors.borderSubtle
                          : AppColors.borderSubtleLight)),
            ),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: !hasVariants
                    ? 'لا توجد خيارات'
                    : (!variantSelected
                    ? 'اختر خياراً أولاً'
                    : (!canAdd ? 'نفذت الكمية' : 'أضف إلى السلة')),
                icon: Icons.shopping_bag_outlined,
                onPressed: canAdd
                    ? () {
                  final variant = product.variants[_selectedVariantIndex];
                  ref
                      .read(cartEntityProvider.notifier)
                      .addItem(product.id, variant.name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'تمت إضافة "${product.name}" (${variant.name}) إلى السلة ✓'),
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
      case 'أقلام ورسم':
        return Icons.edit_outlined;
      case 'أدوات قياس':
        return Icons.straighten_outlined;
      case 'دفاتر وأوراق':
        return Icons.menu_book_outlined;
      case 'لوازم فنية':
        return Icons.palette_outlined;
      case 'أدوات رقمية':
        return Icons.devices_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}