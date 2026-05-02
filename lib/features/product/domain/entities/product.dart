import 'product_variant.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final List<ProductVariant> variants;
  final double rating;
  final int reviewCount;
  final double? discountPercent;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.rating,
    required this.reviewCount,
    this.imageUrl,
    this.variants = const [],
    this.discountPercent,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get hasDiscount =>
      discountPercent != null && discountPercent! > 0;

  double get finalPrice {
    if (!hasDiscount) return price;
    if (discountPercent! >= 100) return 0.0;
    return price - (price * discountPercent! / 100);
  }

  bool get hasAnyStock => variants.any((v) => v.inStock);

  int stockForVariant(String variantName) {
    final match = variants.where((v) => v.name == variantName);
    return match.isEmpty ? 0 : match.first.stock;
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    List<ProductVariant>? variants,
    double? rating,
    int? reviewCount,
    double? discountPercent,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      variants: variants ?? this.variants,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              price == other.price &&
              discountPercent == other.discountPercent &&
              variants == other.variants;

  @override
  int get hashCode =>
      id.hashCode ^
      price.hashCode ^
      (discountPercent?.hashCode ?? 0) ^
      variants.hashCode;

  @override
  String toString() =>
      'Product(id: $id, name: $name, price: $price, category: $category)';
}