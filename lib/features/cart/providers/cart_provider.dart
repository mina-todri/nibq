import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/cart_item_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/cart_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../product/providers/product_provider.dart';

final cartRepositoryProvider = Provider((ref) => CartRepository());

/// Provider for surfacing cart-related errors to the UI.
final cartErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

class CartNotifier extends StateNotifier<List<CartItem>> {
  final String? _uid;
  final Ref _ref;
  StreamSubscription? _sub;

  CartNotifier(this._uid, this._ref) : super([]) {
    if (_uid != null) {
      _listenToCart();
    }
  }

  void _listenToCart() {
    _sub?.cancel();
    _sub = _ref
        .read(cartRepositoryProvider)
        .watchCartItems(_uid!)
        .listen((snapshot) {
      final allProducts = _ref.read(productsStreamProvider).value ?? [];

      state = snapshot.docs.map((doc) {
        final data = doc.data();
        final productId = data['productId'] as String;

        final product = allProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => ProductModel.fromMap(
            Map<String, dynamic>.from(data['product'] ?? {}),
            productId,
          ),
        );

        return CartItem.fromMap(
          {...data, 'product': product.toMap()},
          productId,
        );
      }).toList();
    }, onError: (err) {
      _ref.read(cartErrorProvider.notifier).state = 'فشل تحديث السلة: $err';
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addItem(ProductModel product, String variant) async {
    if (_uid == null) return;

    final oldState = [...state];
    final itemId = '${product.id}_$variant';

    try {
      final productService = _ref.read(productServiceProvider);
      final liveProduct = await productService.getProductById(product.id);
      final liveStock = liveProduct.getStockForVariant(variant);

      if (liveStock <= 0) {
        throw 'نفذت الكمية من هذا النوع';
      }

      final repo = _ref.read(cartRepositoryProvider);
      final doc = await repo.getCartItem(_uid, itemId);

      if (doc.exists) {
        final currentQty = (doc.data()?['quantity'] as num?)?.toInt() ?? 0;
        if (currentQty >= liveStock) {
          throw 'تم الوصول للحد الأقصى للكمية المتاحة';
        }
      }

      // Optimistic local update
      final index = state.indexWhere(
          (i) => i.product.id == product.id && i.selectedVariant == variant);
      if (index != -1) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index)
              state[i].copyWith(quantity: state[i].quantity + 1)
            else
              state[i]
        ];
      } else {
        state = [
          ...state,
          CartItem(product: product, quantity: 1, selectedVariant: variant)
        ];
      }

      if (doc.exists) {
        await repo.updateItemQuantity(_uid, itemId, (doc.data()?['quantity'] as int) + 1);
      } else {
        await repo.addItem(_uid, itemId, {
          'productId': product.id,
          'selectedVariant': variant,
          'quantity': 1,
        });
      }
    } catch (e) {
      state = oldState; // Rollback
      _ref.read(cartErrorProvider.notifier).state = e.toString();
    }
  }

  Future<void> removeItem(String productId, String variant) async {
    if (_uid == null) return;

    final oldState = [...state];
    final itemId = '${productId}_$variant';

    state = state
        .where((i) => !(i.product.id == productId && i.selectedVariant == variant))
        .toList();

    try {
      await _ref.read(cartRepositoryProvider).removeItem(_uid, itemId);
    } catch (e) {
      state = oldState;
      _ref.read(cartErrorProvider.notifier).state = 'فشل حذف المنتج: $e';
    }
  }

  Future<void> updateQuantity(
      String productId, String variant, int quantity) async {
    if (_uid == null) return;

    if (quantity <= 0) {
      await removeItem(productId, variant);
      return;
    }

    final oldState = [...state];

    state = [
      for (final item in state)
        if (item.product.id == productId && item.selectedVariant == variant)
          item.copyWith(quantity: quantity)
        else
          item
    ];

    try {
      final productService = _ref.read(productServiceProvider);
      final liveProduct = await productService.getProductById(productId);
      final liveStock = liveProduct.getStockForVariant(variant);
      
      final clampedQty = liveStock > 0 ? quantity.clamp(1, liveStock) : quantity;

      if (clampedQty != quantity) {
        state = [
          for (final item in state)
            if (item.product.id == productId && item.selectedVariant == variant)
              item.copyWith(quantity: clampedQty)
            else
              item
        ];
      }

      final itemId = '${productId}_$variant';
      await _ref.read(cartRepositoryProvider).updateItemQuantity(_uid, itemId, clampedQty);
    } catch (e) {
      state = oldState;
      _ref.read(cartErrorProvider.notifier).state = 'فشل تحديث الكمية: $e';
    }
  }

  Future<void> clearCart() async {
    if (_uid == null) return;

    final oldState = [...state];
    state = [];

    try {
      await _ref.read(cartRepositoryProvider).clearCart(_uid);
    } catch (e) {
      state = oldState;
      _ref.read(cartErrorProvider.notifier).state = 'فشل إفراغ السلة: $e';
    }
  }
}

final cartProvider =
    StateNotifierProvider.autoDispose<CartNotifier, List<CartItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  return CartNotifier(user?.uid, ref);
});

final cartTotalProvider = Provider.autoDispose<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (total, item) {
    return total + (item.product.finalPrice * item.quantity);
  });
});

final cartCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (total, item) => total + item.quantity);
});
