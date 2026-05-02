import 'dart:io';

import '../entities/product.dart';
import '../repositories/product_repository.dart';

class AddProductUseCase {
  final ProductRepository _repository;

  const AddProductUseCase(this._repository);

  Future<void> call(Product product, {File? imageFile}) =>
      _repository.add(product, imageFile: imageFile);
}
