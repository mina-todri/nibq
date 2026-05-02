import '../repositories/cart_repository.dart';

class RemoveItemFromCartUseCase {
  final CartRepository _repository;

  const RemoveItemFromCartUseCase(this._repository);

  Future<void> call({
    required String userId,
    required String itemId,
  }) =>
      _repository.removeItem(userId, itemId);
}