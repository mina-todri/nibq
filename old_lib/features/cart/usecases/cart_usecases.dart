import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/cart_item_model.dart';
import '../repositories/cart_repository.dart';
import '../usecases/get_live_stock_usecase.dart';

class CartUseCases {
  final CartRepository repository;
  final GetLiveStockUseCase getLiveStock;

  CartUseCases({
    required this.repository,
    required this.getLiveStock,
  });

  int getAvailableStock(String productId, String variantName) {
    return getLiveStock(productId, variantName);
  }

  bool isStockAvailable(String productId, String variantName) {
    return getAvailableStock(productId, variantName) > 0;
  }

  int clampQuantity(String productId, String variantName, int quantity) {
    final stock = getAvailableStock(productId, variantName);
    if (stock <= 0) return quantity;
    return quantity.clamp(1, stock);
  }

  CartItemEntity addItemToState({
    required List<CartItemEntity> currentState,
    required String productId,
    required String variantName,
  }) {
    final existingIndex = currentState.indexWhere(
      (i) => i.productId == productId && i.selectedVariant == variantName,
    );

    if (existingIndex != -1) {
      final item = currentState[existingIndex];
      return item.copyWith(quantity: item.quantity + 1);
    }

    return CartItemEntity(
      productId: productId,
      selectedVariant: variantName,
      quantity: 1,
    );
  }

  List<CartItemEntity> removeItemFromState({
    required List<CartItemEntity> currentState,
    required String productId,
    required String variantName,
  }) {
    return currentState
        .where((i) =>
            !(i.productId == productId && i.selectedVariant == variantName))
        .toList();
  }

  List<CartItemEntity> updateQuantityInState({
    required List<CartItemEntity> currentState,
    required String productId,
    required String variantName,
    required int quantity,
  }) {
    return [
      for (final item in currentState)
        if (item.productId == productId && item.selectedVariant == variantName)
          item.copyWith(quantity: quantity)
        else
          item
    ];
  }

  String buildItemId(String productId, String variantName) {
    return '${productId}::${variantName}';
  }
}
