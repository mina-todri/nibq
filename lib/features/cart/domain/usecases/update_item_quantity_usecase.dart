import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class UpdateItemQuantityUseCase {
  final CartRepository _repository;

  const UpdateItemQuantityUseCase(this._repository);

  /// Sets [quantity] for the item, clamped between 1 and [maxStock].
  /// Caller should remove the item instead of passing quantity <= 0.
  Future<void> call({
    required String userId,
    required String productId,
    required String variantName,
    required int quantity,
    required int maxStock,
  }) {
    assert(quantity > 0, 'Use RemoveItemFromCartUseCase for quantity <= 0');

    final clamped = quantity.clamp(1, maxStock);

    return _repository.setItem(
      userId,
      CartItem(
        productId: productId,
        variantName: variantName,
        quantity: clamped,
      ),
    );
  }
}