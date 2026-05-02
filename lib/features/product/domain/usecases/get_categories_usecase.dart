import '../repositories/product_repository.dart';

/// Derives sorted unique categories from the live product stream.
class GetCategoriesUseCase {
  final ProductRepository _repository;

  const GetCategoriesUseCase(this._repository);

  Stream<List<String>> call() {
    return _repository.watchAll().map((products) {
      final categories = products.map((p) => p.category).toSet().toList()
        ..sort();
      return categories;
    });
  }
}
