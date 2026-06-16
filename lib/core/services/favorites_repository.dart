import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesRepository {
  final FirebaseFirestore _firestore;

  FavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userFavorites(String userId) =>
      _firestore.collection('favorites').doc(userId).collection('items');

  Stream<List<String>> watchFavoriteIds(String userId) {
    return _userFavorites(userId).snapshots().map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  Future<void> addToFavorites(String userId, String productId) async {
    await _userFavorites(userId).doc(productId).set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromFavorites(String userId, String productId) async {
    await _userFavorites(userId).doc(productId).delete();
  }
}
