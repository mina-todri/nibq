import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class AddItemToCartUseCase {
  final CartRepository _repository;

  const AddItemToCartUseCase(this._repository);

  /// Increments quantity by 1, capped at [maxStock].
  /// Throws if the item is already at max stock.
  Future<void> call({
    required String userId,
    required List<CartItem> currentItems,
    required String productId,
    required String variantName,
    required int maxStock,
  }) {
    if (maxStock <= 0) {
      throw Exception('هذا الخيار غير متوفر في المخزن');
    }

    final existing = _find(currentItems, productId, variantName);
    final currentQty = existing?.quantity ?? 0;

    if (currentQty >= maxStock) {
      throw Exception('تم الوصول للحد الأقصى للكمية المتاحة ($maxStock)');
    }

    final updated = CartItem(
      productId: productId,
      variantName: variantName,
      quantity: currentQty + 1,
    );

    return _repository.setItem(userId, updated);
  }

  CartItem? _find(
      List<CartItem> items,
      String productId,
      String variantName,
      ) {
    return items
        .where((i) => i.productId == productId && i.variantName == variantName)
        .cast<CartItem?>()
        .firstOrNull;
  }
}