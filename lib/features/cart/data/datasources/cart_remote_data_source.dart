import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';

abstract interface class CartRemoteDataSource {
  Stream<List<CartItemModel>> watchItems(String userId);
  Future<void> setItem(String userId, CartItem item);
  Future<void> removeItem(String userId, String itemId);
  Future<void> clearCart(String userId, List<CartItem> items);
}

class FirebaseCartDataSource implements CartRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirebaseCartDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// `users/{uid}/cart/{itemId}`
  CollectionReference<Map<String, dynamic>> _cartRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('cart');

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<CartItemModel>> watchItems(String userId) {
    return _cartRef(userId).snapshots().map(
          (snap) => snap.docs
          .map((doc) => CartItemModel.fromMap(doc.data()))
          .toList(),
    );
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<void> setItem(String userId, CartItem item) {
    return _cartRef(userId).doc(item.itemId).set(
      CartItemModel(
        productId: item.productId,
        variantName: item.variantName,
        quantity: item.quantity,
      ).toMap(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> removeItem(String userId, String itemId) {
    return _cartRef(userId).doc(itemId).delete();
  }

  /// Deletes all items in batches — Firestore batch limit is 500 ops.
  @override
  Future<void> clearCart(String userId, List<CartItem> items) async {
    const batchLimit = 499;
    final ids = items.map((i) => i.itemId).toList();

    for (var i = 0; i < ids.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = ids.skip(i).take(batchLimit);
      for (final id in chunk) {
        batch.delete(_cartRef(userId).doc(id));
      }
      await batch.commit();
    }
  }
}