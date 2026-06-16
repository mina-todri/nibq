// lib/shared/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_radius.dart';
import '../../core/constants/app_constants.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDiscount = originalPrice != null && originalPrice! > price;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.all(AppRadius.xl),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: imageUrl == null || imageUrl!.isEmpty
                        ? Center(
                            child: Icon(Icons.image_outlined,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 40),
                          )
                        : Image.network(imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 36))),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite
                              ? colorScheme.secondary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${((originalPrice! - price) / originalPrice! * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.bodyXs.copyWith(
                            color: colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (hasDiscount) ...[
                    Text(
                      AppConstants.formatEGP(originalPrice!),
                      style: AppTextStyles.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      AppConstants.formatEGP(price),
                      style: AppTextStyles.displayMd
                          .copyWith(color: colorScheme.secondary),
                      maxLines: 1,
                    ),
                  ] else
                    Text(
                      AppConstants.formatEGP(price),
                      style: AppTextStyles.displayMd
                          .copyWith(color: colorScheme.secondary),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
