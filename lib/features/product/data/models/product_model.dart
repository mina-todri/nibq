import '../../domain/entities/product.dart';
import 'product_variant_model.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.category,
    required super.rating,
    required super.reviewCount,
    super.imageUrl,
    super.variants,
    super.discountPercent,
  });

  // ── Firestore → Model ─────────────────────────────────────────────────────

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl']?.toString(),
      category: map['category']?.toString() ?? '',
      variants: _parseVariants(map['variants']),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      discountPercent: (map['discount'] as num?)?.toDouble(),
    );
  }

  static List<ProductVariantModel> _parseVariants(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((item) {
          if (item is Map) {
            return ProductVariantModel.fromMap(Map<String, dynamic>.from(item));
          }
          if (item is String) {
            // Legacy format — migrate gracefully with stock 0.
            return ProductVariantModel.fromLegacyString(item);
          }
          return null;
        })
        .whereType<ProductVariantModel>()
        .toList();
  }

  // ── Model → Firestore ─────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'variants': variants
        .map((v) => ProductVariantModel(name: v.name, stock: v.stock).toMap())
        .toList(),
    'rating': rating,
    'reviewCount': reviewCount,
    'discount': discountPercent,
  };
}
