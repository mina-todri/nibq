import '../entities/cart_item.dart';

abstract interface class CartRepository {
  /// Live stream of the user's cart items.
  Stream<List<CartItem>> watchItems(String userId);

  /// Writes a cart item — creates or overwrites.
  Future<void> setItem(String userId, CartItem item);

  /// Removes a single item by productId + variantName.
  Future<void> removeItem(String userId, String itemId);

  /// Deletes all items in the cart.
  Future<void> clearCart(String userId, List<CartItem> items);
}