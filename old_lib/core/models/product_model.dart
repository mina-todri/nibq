
class ProductVariant {
  final String name;
  final int stock;

  const ProductVariant({
    required this.name,
    required this.stock,
  });

  ProductVariant copyWith({String? name, int? stock}) {
    return ProductVariant(
      name: name ?? this.name,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'stock': stock};

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      name: map['name']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductVariant &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              stock == other.stock;

  @override
  int get hashCode => name.hashCode ^ stock.hashCode;

  @override
  String toString() => 'ProductVariant(name: $name, stock: $stock)';
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final List<ProductVariant> variants;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final double? discount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.variants = const [],
    required this.rating,
    required this.reviewCount,
    this.isFavorite = false,
    this.discount,
  });

  /// Total stock across all variants. If no variants, product is considered
  /// always unavailable (stock must be managed per-variant).
  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);

  /// Returns true if ANY variant has stock > 0.
  bool get hasAnyStock => variants.any((v) => v.stock > 0);

  int stockForVariant(String variantName) {
    final match = variants.where((v) => v.name == variantName);
    return match.isEmpty ? 0 : match.first.stock;
  }

  double get finalPrice {
    if (discount == null || discount! <= 0) return price;
    if (discount! >= 100) return 0.0;
    return price - (price * discount! / 100);
  }

  double get effectivePrice => finalPrice;

  bool get hasDiscount => discount != null && discount! > 0;

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    List<ProductVariant>? variants,
    double? rating,
    int? reviewCount,
    bool? isFavorite,
    double? discount,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      variants: variants ?? this.variants,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      discount: discount ?? this.discount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'variants': variants.map((v) => v.toMap()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
      'discount': discount,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawVariants = map['variants'];
    List<ProductVariant> parsedVariants = [];

    if (rawVariants is List) {
      for (final item in rawVariants) {
        if (item is Map) {
          // New format: {name, stock}
          parsedVariants.add(ProductVariant.fromMap(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          // Legacy format: plain strings — migrate with stock 0
          parsedVariants.add(ProductVariant(name: item, stock: 0));
        }
      }
    }

    return ProductModel(
      id: documentId,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl']?.toString(),
      category: map['category']?.toString() ?? '',
      variants: parsedVariants,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isFavorite: false,
      discount: (map['discount'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              description == other.description &&
              price == other.price &&
              imageUrl == other.imageUrl &&
              category == other.category &&
              variants == other.variants &&
              rating == other.rating &&
              reviewCount == other.reviewCount &&
              isFavorite == other.isFavorite &&
              discount == other.discount;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      imageUrl.hashCode ^
      category.hashCode ^
      variants.hashCode ^
      rating.hashCode ^
      reviewCount.hashCode ^
      isFavorite.hashCode ^
      discount.hashCode;

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, category: $category, variants: $variants, discount: $discount)';
  }
}