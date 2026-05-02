import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_variant.dart';
import '../providers/product_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends ConsumerState<ProductDetailScreen> {
  ProductVariant? _selectedVariant;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productByIdProvider(widget.productId));

    if (product == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Auto-select first in-stock variant on first render.
    _selectedVariant ??= product.variants
        .where((v) => v.inStock)
        .cast<ProductVariant?>()
        .firstOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProductImage(imageUrl: product.imageUrl),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + category
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  _PriceRow(product: product),
                  const SizedBox(height: 16),

                  // Rating
                  _RatingRow(product: product),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'الوصف',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 24),

                  // Variants
                  if (product.variants.isNotEmpty) ...[
                    Text(
                      'الخيارات المتاحة',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _VariantSelector(
                      variants: product.variants,
                      selected: _selectedVariant,
                      onSelect: (v) =>
                          setState(() => _selectedVariant = v),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stock status
                  _StockBadge(
                    inStock: _selectedVariant?.inStock ??
                        product.hasAnyStock,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Add to cart ───────────────────────────────────────────────────────
      bottomNavigationBar: _AddToCartBar(
        product: product,
        selectedVariant: _selectedVariant,
      ),
    );
  }
}

// ── Sub-widgets (dumb, no Riverpod) ──────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_outlined,
            size: 64, color: Colors.grey),
      );
    }
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.broken_image_outlined,
            size: 64, color: Colors.grey),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Product product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${product.finalPrice.toStringAsFixed(2)} ر.س',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '${product.price.toStringAsFixed(2)} ر.س',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${product.discountPercent!.toInt()}%',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final Product product;

  const _RatingRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          product.rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 4),
        Text(
          '(${product.reviewCount})',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

class _VariantSelector extends StatelessWidget {
  final List<ProductVariant> variants;
  final ProductVariant? selected;
  final void Function(ProductVariant) onSelect;

  const _VariantSelector({
    required this.variants,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: variants.map((variant) {
        final isSelected = selected?.name == variant.name;
        final outOfStock = !variant.inStock;

        return GestureDetector(
          onTap: outOfStock ? null : () => onSelect(variant),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: outOfStock
                    ? Colors.grey.shade300
                    : isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              variant.name,
              style: TextStyle(
                color: outOfStock
                    ? Colors.grey.shade400
                    : isSelected
                    ? Colors.white
                    : null,
                decoration: outOfStock
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool inStock;

  const _StockBadge({required this.inStock});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          inStock ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 18,
          color: inStock ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 6),
        Text(
          inStock ? 'متوفر في المخزن' : 'غير متوفر',
          style: TextStyle(color: inStock ? Colors.green : Colors.red),
        ),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  final Product product;
  final ProductVariant? selectedVariant;

  const _AddToCartBar({
    required this.product,
    required this.selectedVariant,
  });

  bool get _canAdd {
    if (product.variants.isEmpty) return false;
    return selectedVariant?.inStock ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _canAdd
                ? () {
              // Cart feature will hook here.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تمت إضافة ${product.name} إلى السلة',
                  ),
                ),
              );
            }
                : null,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('إضافة إلى السلة'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}