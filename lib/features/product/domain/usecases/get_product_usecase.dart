import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductUseCase {
  final ProductRepository _repository;

  const GetProductUseCase(this._repository);

  Future<Product?> call(String id) => _repository.getById(id);
}