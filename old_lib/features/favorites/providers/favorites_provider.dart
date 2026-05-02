import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/product_model.dart';
import '../../product/providers/product_provider.dart';
import '../../auth/providers/auth_provider.dart';

final favoritesErrorProvider = StateProvider.autoDispose<String?>((
    ref) => null);

class FavoritesNotifier extends StateNotifier<List<String>> {
  final String? _uid;
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  FavoritesNotifier(this._uid, this._ref) : super([]) {
    if (_uid != null) {
      _listenToFavorites();
    }
  }

  void _listenToFavorites() {
    _sub?.cancel();
    _sub = _firestore
        .collection('favorites')
        .doc(_uid)
        .collection('items')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) => doc.id).toList();
    }, onError: (err) {
      _ref
          .read(favoritesErrorProvider.notifier)
          .state = 'فشل تحديث المفضلة: $err';
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> toggle(String productId) async {
    if (_uid == null) return;

    final oldState = [...state];
    final isRemoving = state.contains(productId);

    // 1. Optimistic local update
    if (isRemoving) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }

    try {
      final docRef = _firestore
          .collection('favorites')
          .doc(_uid)
          .collection('items')
          .doc(productId);

      if (isRemoving) {
        await docRef.delete();
      } else {
        await docRef.set({'addedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      state = oldState; // Rollback
      _ref
          .read(favoritesErrorProvider.notifier)
          .state = 'فشل تعديل المفضلة: $e';
    }
  }
}

final favoriteIdsProvider = StateNotifierProvider.autoDispose<
    FavoritesNotifier,
    List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  return FavoritesNotifier(user?.uid, ref);
});

/// 6. FIX silent empty state in favoritesProvider: Explicitly handle loading/error of stream
final favoritesProvider = Provider.autoDispose<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final favoriteIds = ref.watch(favoriteIdsProvider);

  return productsAsync.when(
    data: (products) {
      final favs = products.where((p) => favoriteIds.contains(p.id)).toList();
      // Synchronous guard for slow stream hydration
      if (favs.isEmpty && favoriteIds.isNotEmpty) {
        Future.microtask(() => ref.read(favoritesErrorProvider.notifier).state = 'جارٍ تحميل المنتجات...');
      }
      return favs;
    },
    loading: () => <ProductModel>[],
    error: (_, __) => <ProductModel>[],
  );
});
