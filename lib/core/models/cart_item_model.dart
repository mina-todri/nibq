// lib/core/models/cart_item_model.dart

import 'product_model.dart';

/// Represents a single line-item in the user's shopping cart.
///
/// Changes vs original:
/// - [FIX] `hashCode` replaced XOR chain with `Object.hash()`.
/// - [FIX] `fromMap()` now has a defensive fallback: if the nested `product`
///   map is absent or malformed, a minimal ProductModel is constructed from
///   the top-level `productId` rather than crashing silently with an empty model.
/// - [IMPROVEMENT] Added `totalPrice` convenience getter used in cart total
///   calculations to avoid spreading price logic across the UI.
class CartItem {
  final ProductModel product;
  final String selectedVariant;
  final int quantity;

  const CartItem({
    required this.product,
    required this.selectedVariant,
    required this.quantity,
  });

  /// The line-item total using the product's effective (post-discount) price.
  double get totalPrice => product.finalPrice * quantity;

  CartItem copyWith({
    ProductModel? product,
    String? selectedVariant,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'productId': product.id,
      'selectedVariant': selectedVariant,
      'quantity': quantity,
    };
  }

  /// Deserialises a [CartItem] from a Firestore map.
  ///
  /// [productId] is the Firestore document ID and is always required.
  /// The nested `product` sub-map is optional: if absent the item is still
  /// created with a stub model so the cart doesn't crash — the caller should
  /// then refresh product details from the repository.
  factory CartItem.fromMap(Map<String, dynamic> map, String productId) {
    final productMap = map['product'];
    final ProductModel resolvedProduct;

    if (productMap is Map && productMap.isNotEmpty) {
      resolvedProduct = ProductModel.fromMap(
        Map<String, dynamic>.from(productMap),
        productId,
      );
    } else {
      // Stub — enough to render the cart entry; price/name populated later.
      resolvedProduct = ProductModel.fromMap(const {}, productId);
    }

    return CartItem(
      product: resolvedProduct,
      selectedVariant: map['selectedVariant']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CartItem &&
              runtimeType == other.runtimeType &&
              product == other.product &&
              selectedVariant == other.selectedVariant &&
              quantity == other.quantity;

  @override
  int get hashCode => Object.hash(product, selectedVariant, quantity);

  @override
  String toString() => 'CartItem('
      'product: $product, '
      'selectedVariant: $selectedVariant, '
      'quantity: $quantity)';
}