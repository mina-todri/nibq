import 'package:cloud_firestore/cloud_firestore.dart';

class CartRepository {
  final FirebaseFirestore _firestore;

  CartRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userCartItems(String userId) =>
      _firestore.collection('carts').doc(userId).collection('items');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCartItems(String userId) {
    return _userCartItems(userId).snapshots();
  }

  Future<void> updateItemQuantity(String userId, String itemId, int quantity) async {
    await _userCartItems(userId).doc(itemId).update({'quantity': quantity});
  }

  Future<void> addItem(String userId, String itemId, Map<String, dynamic> data) async {
    await _userCartItems(userId).doc(itemId).set(data);
  }

  Future<void> removeItem(String userId, String itemId) async {
    await _userCartItems(userId).doc(itemId).delete();
  }

  Future<void> clearCart(String userId) async {
    final collection = _userCartItems(userId);
    final snapshots = await collection.get();

    const batchSize = 499;
    for (int i = 0; i < snapshots.docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = snapshots.docs.skip(i).take(batchSize);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCartItem(String userId, String itemId) {
    return _userCartItems(userId).doc(itemId).get();
  }
}
