// lib/features/favorites/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/empty_state_widget.dart';
import 'providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'المفضلة', showBack: false),
      body: favorites.isEmpty
          ? const EmptyStateWidget(
              title: 'المفضلة فارغة',
              message: 'اضغط على قلب أي منتج لإضافته إلى قائمتك المفضلة',
              icon: Icons.favorite_border,
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: favorites.length,
              itemBuilder: (_, i) {
                final p = favorites[i];
                return ProductCard(
                  name: p.name,
                  price: p.finalPrice,
                  originalPrice: p.hasDiscount ? p.price : null,
                  imageUrl: p.imageUrl,
                  isFavorite: favoriteIds.contains(p.id),
                  onFavoriteTap: () =>
                      ref.read(favoriteIdsProvider.notifier).toggle(p.id),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.product, arguments: p),
                );
              },
            ),
    );
  }
}
