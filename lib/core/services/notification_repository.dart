import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userNotifications(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    debugPrint('🔔 Starting watchNotifications for user: $userId');
    return _userNotifications(userId)
        .snapshots()
        .map((snap) {
          debugPrint('🔔 Notifications snapshot received: ${snap.docs.length} docs');
          final list = snap.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList();
          // Sort in-memory to handle cases where createdAt is temporarily null (server timestamp delay)
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _userNotifications(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final unread = await _userNotifications(userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> createNotification(String userId, NotificationModel notification) async {
    await _userNotifications(userId).add(notification.toMap());
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _userNotifications(userId).doc(notificationId).delete();
  }
}
