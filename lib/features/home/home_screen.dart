// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../product/providers/product_provider.dart';
import '../cart/providers/cart_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../favorites/providers/favorites_provider.dart';
import '../notifications/providers/notifications_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRouter.cart)
            .then((_) { if (mounted) setState(() => _navIndex = 0); });
      case 2:
        Navigator.pushNamed(context, AppRouter.notifications)
            .then((_) { if (mounted) setState(() => _navIndex = 0); });
      case 3:
        Navigator.pushNamed(context, AppRouter.profile)
            .then((_) { if (mounted) setState(() => _navIndex = 0); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.displayName?.split(' ').first ?? 'طالب';
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final cartCount = ref.watch(cartCountProvider);
    final unreadNotificationsCount = ref.watch(unreadNotificationsCountProvider);
    // 4. Watch available categories provider
    final categories = ref.watch(availableCategoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('الخروج'),
            content: const Text('هل تريد الخروج من التطبيق؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('نعم')),
            ],
          ),
        );
        if (shouldExit == true) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.person,
                            color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('أهلاً، $userName',
                                style: AppTextStyles.bodySm.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                            Text('اكتشف أدواتك الإبداعية',
                                style: AppTextStyles.displayLg.copyWith(
                                    color: colorScheme.onSurface)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_outlined,
                                color: colorScheme.onSurface),
                            if (unreadNotificationsCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () => Navigator.pushNamed(
                            context, AppRouter.notifications),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.search),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: colorScheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: 10),
                          Text('ابحث عن أداة أو منتج...',
                              style: AppTextStyles.bodyMd.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Dynamic Categories List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (ctx, idx) =>
                      const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final sel = categories[i] == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(selectedCategoryProvider.notifier)
                                .state = categories[i];
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: sel
                                  ? colorScheme.primary
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: sel
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant),
                            ),
                            child: Text(
                              categories[i],
                              style: AppTextStyles.bodySm.copyWith(
                                color: sel
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Products grid
              productsAsync.when(
                data: (allProducts) {
                  final products = selectedCategory == 'الكل'
                      ? allProducts
                      : allProducts.where((p) => p.category == selectedCategory).toList();

                  if (products.isEmpty) {
                    return const SliverFillRemaining(
                      child: EmptyStateWidget(
                        title: 'لا توجد منتجات',
                        message: 'لم يتم العثور على منتجات في هذا القسم حالياً',
                        icon: Icons.inventory_2_outlined,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(
                          name: products[i].name,
                          price: products[i].finalPrice,
                          originalPrice: products[i].hasDiscount ? products[i].price : null,
                          imageUrl: products[i].imageUrl,
                          isFavorite: favoriteIds.contains(products[i].id),
                          onFavoriteTap: () => ref
                              .read(favoriteIdsProvider.notifier)
                              .toggle(products[i].id),
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.product,
                              arguments: products[i]),
                        ),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(child: LoadingWidget()),
                error: (e, st) => SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: 'فشل تحميل المنتجات',
                    onRetry: () => ref.refresh(productsStreamProvider),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _navIndex,
          cartCount: cartCount,
          notificationsCount: unreadNotificationsCount,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
