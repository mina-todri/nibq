import 'dart:io';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _dataSource;

  const ProductRepositoryImpl(this._dataSource);

  @override
  Stream<List<Product>> watchAll() => _dataSource.watchAll();

  @override
  Future<Product?> getById(String id) => _dataSource.getById(id);

  @override
  Future<void> add(Product product, {File? imageFile}) =>
      _dataSource.add(_toModel(product), imageFile: imageFile);

  @override
  Future<void> update(Product product, {File? imageFile}) =>
      _dataSource.update(_toModel(product), imageFile: imageFile);

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Converts a domain [Product] to a [ProductModel] for the data source.
  ProductModel _toModel(Product p) => ProductModel(
    id: p.id,
    name: p.name,
    description: p.description,
    price: p.price,
    imageUrl: p.imageUrl,
    category: p.category,
    variants: p.variants,
    rating: p.rating,
    reviewCount: p.reviewCount,
    discountPercent: p.discountPercent,
  );
}
