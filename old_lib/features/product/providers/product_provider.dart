import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/product_service.dart';

final productServiceProvider = Provider((ref) => ProductService());

/// The currently selected filter category.
final selectedCategoryProvider = StateProvider<String>((ref) => 'الكل');

/// Live stream of ALL products from Firestore.
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productServiceProvider).streamProducts();
});

/// Primary provider for products, filtered by category.
/// All customer-facing screens should consume this.
final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.maybeWhen(
    data: (products) {
      if (selectedCategory == 'الكل') return products;
      return products.where((p) => p.category == selectedCategory).toList();
    },
    orElse: () => [],
  );
});

/// 3. Derived provider for dynamic categories
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.maybeWhen(
    data: (products) {
      final cats = products.map((p) => p.category).toSet().toList();
      cats.sort();
      return ['الكل', ...cats];
    },
    orElse: () => ['الكل'],
  );
});
