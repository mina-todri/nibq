import 'dart:io';

import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProductUseCase {
  final ProductRepository _repository;

  const UpdateProductUseCase(this._repository);

  Future<void> call(Product product, {File? imageFile}) =>
      _repository.update(product, imageFile: imageFile);
}
