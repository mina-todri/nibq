class ProductVariant {
  final String name;
  final int stock;

  const ProductVariant({required this.name, required this.stock});

  bool get inStock => stock > 0;

  ProductVariant copyWith({String? name, int? stock}) {
    return ProductVariant(name: name ?? this.name, stock: stock ?? this.stock);
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
