import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/product_card.dart';
import '../product/providers/product_provider.dart';
import '../favorites/providers/favorites_provider.dart';
import '../../core/models/product_model.dart';
import '../../core/constants/app_constants.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<ProductModel> _filter(List<ProductModel> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final allProducts = ref.watch(filteredProductsProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final results = _filter(allProducts, query);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        color: colorScheme.onSurface, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        style: AppTextStyles.bodyMd.copyWith(color: colorScheme.onSurface),
                        cursorColor: colorScheme.primary,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج...',
                          hintStyle: AppTextStyles.bodyMd
                              .copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                          prefixIcon: Icon(Icons.search,
                              color: colorScheme.onSurfaceVariant, size: 20),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      color: colorScheme.onSurfaceVariant, size: 18),
                                  onPressed: () {
                                    _ctrl.clear();
                                    ref
                                        .read(_searchQueryProvider.notifier)
                                        .state = '';
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (v) =>
                            ref.read(_searchQueryProvider.notifier).state = v,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results count
            if (query.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${results.length} نتيجة لـ "$query"',
                    style: AppTextStyles.bodySm
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),

            // Results grid or empty state
            Expanded(
              child: results.isEmpty && query.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('لا توجد نتائج',
                              style: AppTextStyles.displayMd
                                  .copyWith(color: colorScheme.onSurface)),
                          const SizedBox(height: 8),
                          Text('جرّب كلمة بحث مختلفة',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : query.isEmpty
                      ? _buildSuggestions(context, allProducts)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final p = results[i];
                            return ProductCard(
                              name: p.name,
                              price: p.finalPrice,
                              originalPrice: p.hasDiscount ? p.price : null,
                              imageUrl: p.imageUrl,
                              isFavorite: favoriteIds.contains(p.id),
                              onFavoriteTap: () => ref
                                  .read(favoriteIdsProvider.notifier)
                                  .toggle(p.id),
                              onTap: () => Navigator.pushNamed(
                                  context, AppRouter.product,
                                  arguments: p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, List<ProductModel> all) {
    final categories = all.map((p) => p.category).toSet().toList();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Text('الفئات',
            style: AppTextStyles.bodySm
                .copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map((cat) => GestureDetector(
                    onTap: () {
                      _ctrl.text = cat;
                      ref.read(_searchQueryProvider.notifier).state = cat;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text(cat, style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurface)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Text('جميع المنتجات',
            style: AppTextStyles.bodySm
                .copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...all.take(15).map((p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                  image: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(p.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: p.imageUrl == null || p.imageUrl!.isEmpty
                    ? Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 24)
                    : null,
              ),
              title: Text(p.name, style: AppTextStyles.bodyMd.copyWith(color: colorScheme.onSurface)),
              subtitle: Text(p.category,
                  style: AppTextStyles.bodySm
                      .copyWith(color: colorScheme.onSurfaceVariant)),
              trailing: Text(AppConstants.formatEGP(p.finalPrice),
                  style: AppTextStyles.bodyMd
                      .copyWith(color: colorScheme.secondary)),
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.product, arguments: p),
            )),
      ],
    );
  }
}