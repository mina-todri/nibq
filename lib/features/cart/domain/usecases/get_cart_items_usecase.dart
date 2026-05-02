import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class GetCartItemsUseCase {
  final CartRepository _repository;

  const GetCartItemsUseCase(this._repository);

  Stream<List<CartItem>> call(String userId) => _repository.watchItems(userId);
}
