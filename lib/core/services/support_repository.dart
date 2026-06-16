import 'package:cloud_firestore/cloud_firestore.dart';

class SupportRepository {
  final FirebaseFirestore _firestore;

  SupportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> sendComplaint({
    required String userId,
    required String userName,
    required String? orderId,
    required String type, // e.g., 'order', 'app', 'delivery'
    required String message,
  }) async {
    await _firestore.collection('complaints').add({
      'userId': userId,
      'userName': userName,
      'orderId': orderId,
      'type': type,
      'message': message,
      'status': 'pending', // pending, resolved
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> resolveComplaint(String complaintId, {String? adminResponse, String? userId}) async {
    final batch = _firestore.batch();
    
    final complaintRef = _firestore.collection('complaints').doc(complaintId);
    batch.update(complaintRef, {
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'adminResponse': adminResponse,
    });

    if (userId != null && adminResponse != null) {
      final notifRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();
      
      batch.set(notifRef, {
        'title': 'رد على شكواك',
        'body': adminResponse,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'general',
        'relatedId': complaintId,
      });
    }

    await batch.commit();
  }

  Future<void> submitOrderRating({
    required String orderId,
    required String userId,
    required int rating,
    required String? comment,
  }) async {
    // Update order with rating
    await _firestore.collection('orders').doc(orderId).update({
      'rating': rating,
      'ratingComment': comment,
      'ratedAt': FieldValue.serverTimestamp(),
    });
  }
}
