import '../repositories/product_repository.dart';

class DeleteProductUseCase {
  final ProductRepository _repository;

  const DeleteProductUseCase(this._repository);

  Future<void> call(String id) => _repository.delete(id);
}