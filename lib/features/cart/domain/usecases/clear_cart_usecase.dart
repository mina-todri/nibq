import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class ClearCartUseCase {
  final CartRepository _repository;

  const ClearCartUseCase(this._repository);

  Future<void> call(String userId, List<CartItem> currentItems) =>
      _repository.clearCart(userId, currentItems);
}
