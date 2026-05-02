import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Returns a live stream of products, optionally filtered by category.
class WatchProductsUseCase {
  final ProductRepository _repository;

  const WatchProductsUseCase(this._repository);

  Stream<List<Product>> call({String? category}) {
    return _repository.watchAll().map((products) {
      if (category == null || category.isEmpty) return products;
      return products.where((p) => p.category == category).toList();
    });
  }
}
