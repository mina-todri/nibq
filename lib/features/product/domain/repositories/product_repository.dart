import 'dart:io';

import '../entities/product.dart';

abstract interface class ProductRepository {
  /// Live stream of all products.
  Stream<List<Product>> watchAll();

  /// Fetch a single product by id.
  Future<Product?> getById(String id);

  /// Add a new product. [imageFile] is optional — data layer handles upload.
  Future<void> add(Product product, {File? imageFile});

  /// Update an existing product. [imageFile] replaces the current image if provided.
  Future<void> update(Product product, {File? imageFile});

  /// Permanently delete a product.
  Future<void> delete(String id);
}
