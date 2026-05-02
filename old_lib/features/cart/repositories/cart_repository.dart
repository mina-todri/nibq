import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/cart_item_model.dart';

abstract class CartRepository {
  Stream<List<CartItemEntity>> watchCartItems(String uid);

  Future<void> setCartItem({
    required String uid,
    required String itemId,
    required String productId,
    required String variantName,
    required int quantity,
  });

  Future<void> deleteCartItem({
    required String uid,
    required String itemId,
  });

  Future<void> updateCartItemQuantity({
    required String uid,
    required String itemId,
    required int quantity,
  });

  Future<void> clearCart({
    required String uid,
    required List<CartItemEntity> items,
  });
}

class FirebaseCartRepository implements CartRepository {
  final FirebaseFirestore firestore;

  FirebaseCartRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) {
    return firestore.collection('carts').doc(uid).collection('items');
  }

  @override
  Stream<List<CartItemEntity>> watchCartItems(String uid) {
    return _itemsRef(uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CartItemEntity.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> setCartItem({
    required String uid,
    required String itemId,
    required String productId,
    required String variantName,
    required int quantity,
  }) {
    return _itemsRef(uid).doc(itemId).set({
      'productId': productId,
      'selectedVariant': variantName,
      'quantity': quantity,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCartItem({
    required String uid,
    required String itemId,
  }) {
    return _itemsRef(uid).doc(itemId).delete();
  }

  @override
  Future<void> updateCartItemQuantity({
    required String uid,
    required String itemId,
    required int quantity,
  }) {
    return _itemsRef(uid).doc(itemId).update({'quantity': quantity});
  }

  @override
  Future<void> clearCart({
    required String uid,
    required List<CartItemEntity> items,
  }) async {
    const batchSize = 499;
    final allIds = items
        .map((e) => '${e.productId}::${e.selectedVariant}')
        .toList();

    for (int i = 0; i < allIds.length; i += batchSize) {
      final batch = firestore.batch();
      final chunk = allIds.skip(i).take(batchSize);
      for (final id in chunk) {
        batch.delete(_itemsRef(uid).doc(id));
      }
      await batch.commit();
    }
  }
}
