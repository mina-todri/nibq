import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../providers/product_providers.dart';
import '../providers/product_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    final filtered = ref.watch(filteredProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المنتجات')),
      body: Column(
        children: [
          // ── Category filter ───────────────────────────────────────────────
          const CategoryFilterBar(),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: switch (state) {
              ProductLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              ProductError(:final message) => _ErrorView(
                message: message,
                onRetry: () => ref.invalidate(productProvider),
              ),
              ProductLoaded() when filtered.isEmpty => const _EmptyView(),
              _ => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  return ProductCard(
                    product: product,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.productDetail,
                      arguments: product.id,
                    ),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('لا توجد منتجات', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
