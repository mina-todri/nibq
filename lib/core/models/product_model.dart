/// Represents a specific variant of a product with its own stock.
class ProductVariant {
  final String name;
  final int stock;
  final double? priceOverride; // Optional: if a variant has a different price

  const ProductVariant({
    required this.name,
    required this.stock,
    this.priceOverride,
  });

  bool get isInStock => stock > 0;

  Map<String, dynamic> toMap() => {
        'name': name,
        'stock': stock,
        if (priceOverride != null) 'priceOverride': priceOverride,
      };

  factory ProductVariant.fromMap(Map<String, dynamic> map) => ProductVariant(
        name: map['name']?.toString() ?? '',
        stock: (map['stock'] as num?)?.toInt() ?? 0,
        priceOverride: (map['priceOverride'] as num?)?.toDouble(),
      );

  ProductVariant copyWith({
    String? name,
    int? stock,
    double? priceOverride,
  }) {
    return ProductVariant(
      name: name ?? this.name,
      stock: stock ?? this.stock,
      priceOverride: priceOverride ?? this.priceOverride,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariant &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          stock == other.stock &&
          priceOverride == other.priceOverride;

  @override
  int get hashCode => Object.hash(name, stock, priceOverride);
}

/// Immutable product entity.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final List<ProductVariant> productVariants;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final int totalStock; // Sum of all variant stocks
  final double? discount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.productVariants = const [],
    required this.rating,
    required this.reviewCount,
    this.isFavorite = false,
    this.totalStock = 0,
    this.discount,
  });

  /// The price after applying the discount percentage.
  double get finalPrice {
    if (discount == null || discount! <= 0) return price;
    if (discount! >= 100) return 0.0;
    return price - (price * discount! / 100);
  }

  bool get hasDiscount => discount != null && discount! > 0;
  
  /// A product is in stock if any of its variants have stock, 
  /// or if it has no variants and base stock > 0.
  bool get isInStock => productVariants.isEmpty ? totalStock > 0 : productVariants.any((v) => v.isInStock);

  /// Helper to get stock for a specific variant name.
  int getStockForVariant(String variantName) {
    if (productVariants.isEmpty) return totalStock;
    final variant = productVariants.firstWhere(
      (v) => v.name == variantName,
      orElse: () => const ProductVariant(name: '', stock: 0),
    );
    return variant.stock;
  }

  String? get formattedDiscount =>
      hasDiscount ? '${discount!.toStringAsFixed(0)}%' : null;

  static const Object _sentinel = Object();

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    List<ProductVariant>? productVariants,
    double? rating,
    int? reviewCount,
    bool? isFavorite,
    int? totalStock,
    Object? discount = _sentinel,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      productVariants: productVariants ?? this.productVariants,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      totalStock: totalStock ?? this.totalStock,
      discount: identical(discount, _sentinel)
          ? this.discount
          : discount as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'productVariants': productVariants.map((v) => v.toMap()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
      'totalStock': totalStock,
      'discount': discount,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Handle migration from old 'variants' (List<String>) to 'productVariants'
    List<ProductVariant> parsedVariants = [];
    if (map['productVariants'] != null) {
      parsedVariants = (map['productVariants'] as List)
          .map((v) => ProductVariant.fromMap(Map<String, dynamic>.from(v)))
          .toList();
    } else if (map['variants'] != null || map['sizes'] != null) {
      // Backward compatibility: Convert string list to variant list with shared stock
      final oldList = List<String>.from(map['variants'] ?? map['sizes'] ?? []);
      final sharedStock = (map['stock'] as num?)?.toInt() ?? 0;
      parsedVariants = oldList.map((name) => ProductVariant(name: name, stock: sharedStock)).toList();
    }

    return ProductModel(
      id: documentId,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl']?.toString(),
      category: map['category']?.toString() ?? '',
      productVariants: parsedVariants,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isFavorite: false,
      totalStock: (map['totalStock'] as num?)?.toInt() ?? (map['stock'] as num?)?.toInt() ?? 0,
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
          productVariants == other.productVariants &&
          rating == other.rating &&
          reviewCount == other.reviewCount &&
          isFavorite == other.isFavorite &&
          totalStock == other.totalStock &&
          discount == other.discount;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        price,
        imageUrl,
        category,
        productVariants,
        rating,
        reviewCount,
        isFavorite,
        totalStock,
        discount,
      );
}
