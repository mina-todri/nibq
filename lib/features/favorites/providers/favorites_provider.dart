import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/favorites_repository.dart';
import '../../../core/models/product_model.dart';
import '../../product/providers/product_provider.dart';
import '../../auth/providers/auth_provider.dart';

final favoritesRepositoryProvider = Provider((ref) => FavoritesRepository());

final favoritesErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

final favoriteIdsStreamProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(favoritesRepositoryProvider)
      .watchFavoriteIds(user.uid)
      .handleError((error) {
        if (error.toString().contains('permission-denied')) {
          return [];
        }
        throw error;
      });
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  final String? _uid;
  final Ref _ref;

  FavoritesNotifier(this._uid, this._ref) : super([]) {
    _ref.listen(favoriteIdsStreamProvider, (prev, next) {
      if (next is AsyncData<List<String>>) {
        state = next.value;
      }
    });
  }

  Future<void> toggle(String productId) async {
    if (_uid == null) return;

    final oldState = [...state];
    final isRemoving = state.contains(productId);

    // Optimistic local update
    if (isRemoving) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }

    try {
      final repo = _ref.read(favoritesRepositoryProvider);
      if (isRemoving) {
        await repo.removeFromFavorites(_uid, productId);
      } else {
        await repo.addToFavorites(_uid, productId);
      }
    } catch (e) {
      state = oldState; // Rollback
      _ref.read(favoritesErrorProvider.notifier).state = 'فشل تعديل المفضلة: $e';
    }
  }
}

final favoriteIdsProvider = StateNotifierProvider.autoDispose<FavoritesNotifier, List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  return FavoritesNotifier(user?.uid, ref);
});

final favoritesProvider = Provider.autoDispose<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final favoriteIds = ref.watch(favoriteIdsProvider);

  return productsAsync.when(
    data: (products) {
      return products.where((p) => favoriteIds.contains(p.id)).toList();
    },
    loading: () => <ProductModel>[],
    error: (_, _) => <ProductModel>[],
  );
});
