import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/usecases/add_item_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/remove_item_from_cart_usecase.dart';
import '../../domain/usecases/update_item_quantity_usecase.dart';
import 'cart_state.dart';

class CartNotifier extends StateNotifier<CartState> {
  final String _userId;
  final CartRepository _repository;
  final AddItemToCartUseCase _addItem;
  final RemoveItemFromCartUseCase _removeItem;
  final UpdateItemQuantityUseCase _updateQuantity;
  final ClearCartUseCase _clearCart;

  StreamSubscription<List<CartItem>>? _streamSub;

  CartNotifier({
    required String userId,
    required CartRepository repository,
    required AddItemToCartUseCase addItem,
    required RemoveItemFromCartUseCase removeItem,
    required UpdateItemQuantityUseCase updateQuantity,
    required ClearCartUseCase clearCart,
  })  : _userId = userId,
        _repository = repository,
        _addItem = addItem,
        _removeItem = removeItem,
        _updateQuantity = updateQuantity,
        _clearCart = clearCart,
        super(const CartInitial()) {
    _listen();
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  void _listen() {
    state = const CartLoading();
    _streamSub = _repository.watchItems(_userId).listen(
          (items) => state = CartLoaded(items),
      onError: (Object e) => state = CartError(e.toString()),
    );
  }

  // ── Current items helper ──────────────────────────────────────────────────

  List<CartItem> get _currentItems =>
      state is CartLoaded ? (state as CartLoaded).items : [];

  // ── Mutations — stream drives state, no manual setState ───────────────────

  Future<void> addItem({
    required String productId,
    required String variantName,
    required int maxStock,
  }) async {
    try {
      await _addItem(
        userId: _userId,
        currentItems: _currentItems,
        productId: productId,
        variantName: variantName,
        maxStock: maxStock,
      );
    } catch (e) {
      state = CartError(e.toString());
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _removeItem(userId: _userId, itemId: itemId);
    } catch (e) {
      state = CartError(e.toString());
      rethrow;
    }
  }

  Future<void> updateQuantity({
    required String productId,
    required String variantName,
    required int quantity,
    required int maxStock,
  }) async {
    if (quantity <= 0) {
      final itemId = CartItem(
        productId: productId,
        variantName: variantName,
        quantity: 0,
      ).itemId;
      return removeItem(itemId);
    }
    try {
      await _updateQuantity(
        userId: _userId,
        productId: productId,
        variantName: variantName,
        quantity: quantity,
        maxStock: maxStock,
      );
    } catch (e) {
      state = CartError(e.toString());
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _clearCart(_userId, _currentItems);
    } catch (e) {
      state = CartError(e.toString());
      rethrow;
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}