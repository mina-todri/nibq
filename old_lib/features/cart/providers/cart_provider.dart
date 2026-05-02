import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/cart_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../product/providers/product_provider.dart';
import '../repositories/cart_repository.dart';
import '../usecases/get_live_stock_usecase.dart';
import '../usecases/cart_usecases.dart';

final cartErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return FirebaseCartRepository();
});

final cartUseCasesProvider = Provider<CartUseCases>((ref) {
  return CartUseCases(
    repository: ref.watch(cartRepositoryProvider),
    getLiveStock: GetLiveStockUseCase(ref),
  );
});

class CartNotifier extends StateNotifier<List<CartItemEntity>> {
  final String? _uid;
  final Ref _ref;
  final CartRepository _repository;
  final CartUseCases _useCases;
  StreamSubscription<List<CartItemEntity>>? _sub;

  CartNotifier({
    required String? uid,
    required Ref ref,
    required CartRepository repository,
    required CartUseCases useCases,
  })  : _uid = uid,
        _ref = ref,
        _repository = repository,
        _useCases = useCases,
        super([]) {
    if (uid != null) _listenToCart();
  }

  void _listenToCart() {
    _sub?.cancel();
    _sub = _repository.watchCartItems(_uid!).listen(
          (items) => state = items,
      onError: (err) {
        _ref.read(cartErrorProvider.notifier).state = 'فشل تحديث السلة: $err';
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addItem(String productId, String variantName) async {
    if (_uid == null) return;
    try {
      if (!_useCases.isStockAvailable(productId, variantName)) {
        throw Exception('نفذت الكمية لهذا الخيار');
      }
      final currentQty = _getCurrentQuantity(productId, variantName);
      final stock = _useCases.getAvailableStock(productId, variantName);
      if (currentQty >= stock) {
        throw Exception('تم الوصول للحد الأقصى للكمية المتاحة ($stock)');
      }
      final itemId = _useCases.buildItemId(productId, variantName);
      await _repository.setCartItem(
        uid: _uid!,
        itemId: itemId,
        productId: productId,
        variantName: variantName,
        quantity: currentQty + 1,
      );
    } catch (e) {
      _ref.read(cartErrorProvider.notifier).state = e.toString();
    }
  }

  Future<void> removeItem(String productId, String variant) async {
    if (_uid == null) return;
    final oldState = [...state];
    state = _useCases.removeItemFromState(
      currentState: state,
      productId: productId,
      variantName: variant,
    );
    try {
      final itemId = _useCases.buildItemId(productId, variant);
      await _repository.deleteCartItem(uid: _uid!, itemId: itemId);
    } catch (e) {
      state = oldState;
      _ref.read(cartErrorProvider.notifier).state = 'فشل حذف المنتج: $e';
    }
  }

  Future<void> updateQuantity(
      String productId, String variantName, int quantity) async {
    if (_uid == null) return;
    if (quantity <= 0) {
      await removeItem(productId, variantName);
      return;
    }
    final oldState = [...state];
    try {
      final clampedQty =
      _useCases.clampQuantity(productId, variantName, quantity);
      state = _useCases.updateQuantityInState(
        currentState: state,
        productId: productId,
        variantName: variantName,
        quantity: clampedQty,
      );
      final itemId = _useCases.buildItemId(productId, variantName);
      await _repository.updateCartItemQuantity(
        uid: _uid!,
        itemId: itemId,
        quantity: clampedQty,
      );
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
      await _repository.clearCart(uid: _uid!, items: oldState);
    } catch (e) {
      state = oldState;
      _ref.read(cartErrorProvider.notifier).state = 'فشل إفراغ السلة: $e';
    }
  }

  int _getCurrentQuantity(String productId, String variantName) {
    return state
        .firstWhere(
          (i) => i.productId == productId && i.selectedVariant == variantName,
      orElse: () => const CartItemEntity(
          productId: '', selectedVariant: '', quantity: 0),
    )
        .quantity;
  }
}

final cartEntityProvider =
StateNotifierProvider.autoDispose<CartNotifier, List<CartItemEntity>>(
      (ref) {
    final user = ref.watch(currentUserProvider);
    return CartNotifier(
      uid: user?.uid,
      ref: ref,
      repository: ref.watch(cartRepositoryProvider),
      useCases: ref.watch(cartUseCasesProvider),
    );
  },
);

final cartProvider = Provider.autoDispose<List<CartItem>>((ref) {
  final cartEntities = ref.watch(cartEntityProvider);
  final allProducts = ref.watch(productsStreamProvider).value ?? [];
  if (allProducts.isEmpty) return [];
  final List<CartItem> uiCartItems = [];
  for (final entity in cartEntities) {
    try {
      final product = allProducts.firstWhere((p) => p.id == entity.productId);
      uiCartItems.add(CartItem(
        product: product,
        selectedVariant: entity.selectedVariant,
        quantity: entity.quantity,
      ));
    } catch (_) {}
  }
  return uiCartItems;
});

final cartTotalProvider = Provider.autoDispose<double>((ref) {
  return ref.watch(cartProvider).fold(
      0.0, (sum, item) => sum + (item.product.finalPrice * item.quantity));
});

final cartCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(cartEntityProvider)
      .fold(0, (sum, item) => sum + item.quantity);
});