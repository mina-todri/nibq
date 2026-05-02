import '../../domain/entities/product_variant.dart';

class ProductVariantModel extends ProductVariant {
  const ProductVariantModel({required super.name, required super.stock});

  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantModel(
      name: map['name']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  /// Supports legacy Firestore docs where variants were plain strings.
  factory ProductVariantModel.fromLegacyString(String name) {
    return ProductVariantModel(name: name, stock: 0);
  }

  Map<String, dynamic> toMap() => {'name': name, 'stock': stock};
}
