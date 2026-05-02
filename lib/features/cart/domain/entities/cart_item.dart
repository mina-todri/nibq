/// Pure domain entity.
/// Holds only IDs — no Product object, no Firebase types.
class CartItem {
  final String productId;
  final String variantName;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.variantName,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      variantName: variantName,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Unique key per product+variant combination.
  /// Used as the Firestore document id and for list lookups.
  String get itemId => '${productId}::$variantName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          variantName == other.variantName;

  @override
  int get hashCode => productId.hashCode ^ variantName.hashCode;

  @override
  String toString() =>
      'CartItem(productId: $productId, variantName: $variantName, quantity: $quantity)';
}
