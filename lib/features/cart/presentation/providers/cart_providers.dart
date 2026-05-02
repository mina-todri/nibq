import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../data/datasources/cart_remote_data_source.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/usecases/add_item_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/get_cart_items_usecase.dart';
import '../../domain/usecases/remove_item_from_cart_usecase.dart';
import '../../domain/usecases/update_item_quantity_usecase.dart';
import 'cart_notifier.dart';
import 'cart_state.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final cartDataSourceProvider = Provider<CartRemoteDataSource>(
  (_) => FirebaseCartDataSource(),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(ref.watch(cartDataSourceProvider)),
);

// ── Use cases ─────────────────────────────────────────────────────────────────

final addItemUseCaseProvider = Provider(
  (ref) => AddItemToCartUseCase(ref.watch(cartRepositoryProvider)),
);

final removeItemUseCaseProvider = Provider(
  (ref) => RemoveItemFromCartUseCase(ref.watch(cartRepositoryProvider)),
);

final updateQuantityUseCaseProvider = Provider(
  (ref) => UpdateItemQuantityUseCase(ref.watch(cartRepositoryProvider)),
);

final clearCartUseCaseProvider = Provider(
  (ref) => ClearCartUseCase(ref.watch(cartRepositoryProvider)),
);

final getCartItemsUseCaseProvider = Provider(
  (ref) => GetCartItemsUseCase(ref.watch(cartRepositoryProvider)),
);

// ── Core state ────────────────────────────────────────────────────────────────

/// Cart is user-scoped — disposed and recreated on auth change.
final cartProvider = StateNotifierProvider.autoDispose
    .family<CartNotifier, CartState, String>(
      (ref, userId) => CartNotifier(
        userId: userId,
        repository: ref.watch(cartRepositoryProvider),
        addItem: ref.watch(addItemUseCaseProvider),
        removeItem: ref.watch(removeItemUseCaseProvider),
        updateQuantity: ref.watch(updateQuantityUseCaseProvider),
        clearCart: ref.watch(clearCartUseCaseProvider),
      ),
    );

/// Safe access point — returns CartInitial when no user is signed in.
/// All UI consumes this, never [cartProvider] directly.
final activeCartProvider = Provider.autoDispose<CartState>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const CartInitial();
  return ref.watch(cartProvider(user.id));
});

final activeCartNotifierProvider = Provider.autoDispose<CartNotifier?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(cartProvider(user.id).notifier);
});

// ── Derived ───────────────────────────────────────────────────────────────────

/// Loaded items, empty list while loading or on error.
final cartItemsProvider = Provider.autoDispose<List<CartItem>>((ref) {
  final state = ref.watch(activeCartProvider);
  return state is CartLoaded ? state.items : [];
});

/// Total number of units across all items (for badge display).
final cartCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(cartItemsProvider)
      .fold(0, (sum, item) => sum + item.quantity);
});

/// Total price — resolves product price from the product provider.
final cartTotalProvider = Provider.autoDispose<double>((ref) {
  final items = ref.watch(cartItemsProvider);
  final products = ref.watch(productsListProvider);

  return items.fold(0.0, (sum, item) {
    final product = products
        .where((p) => p.id == item.productId)
        .cast<dynamic>()
        .firstOrNull;
    if (product == null) return sum;
    return sum + (product.finalPrice as double) * item.quantity;
  });
});

/// True while the cart stream is loading.
final cartLoadingProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(activeCartProvider) is CartLoading,
);
