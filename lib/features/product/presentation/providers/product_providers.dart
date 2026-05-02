import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/product_remote_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/watch_products_usecase.dart';
import 'product_notifier.dart';
import 'product_state.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final productDataSourceProvider = Provider<ProductRemoteDataSource>(
  (_) => FirebaseProductDataSource(),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ref.watch(productDataSourceProvider)),
);

// ── Use cases ─────────────────────────────────────────────────────────────────

final watchProductsUseCaseProvider = Provider(
  (ref) => WatchProductsUseCase(ref.watch(productRepositoryProvider)),
);

final getCategoriesUseCaseProvider = Provider(
  (ref) => GetCategoriesUseCase(ref.watch(productRepositoryProvider)),
);

// ── Core state ────────────────────────────────────────────────────────────────

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(ref.watch(productRepositoryProvider)),
);

// ── Derived ───────────────────────────────────────────────────────────────────

/// All loaded products, empty list while loading or on error.
final productsListProvider = Provider<List<Product>>((ref) {
  final state = ref.watch(productProvider);
  return state is ProductLoaded ? state.products : [];
});

/// Selected category filter. Empty string means "show all".
final selectedCategoryProvider = StateProvider<String>((_) => '');

/// Products filtered by [selectedCategoryProvider].
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsListProvider);
  final category = ref.watch(selectedCategoryProvider);
  if (category.isEmpty) return products;
  return products.where((p) => p.category == category).toList();
});

/// Sorted unique category list derived from live products.
final categoriesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(getCategoriesUseCaseProvider).call(),
);

/// A single product by id, read from the already-loaded list.
final productByIdProvider = Provider.family<Product?, String>((ref, id) {
  return ref.watch(productsListProvider).where((p) => p.id == id).firstOrNull;
});

/// True while the initial product stream is loading.
final productLoadingProvider = Provider<bool>(
  (ref) => ref.watch(productProvider) is ProductLoading,
);
