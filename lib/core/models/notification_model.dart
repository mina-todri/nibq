import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderStatus,
  promotion,
  newProduct,
  general;

  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'orderstatus':
        return NotificationType.orderStatus;
      case 'promotion':
        return NotificationType.promotion;
      case 'newproduct':
        return NotificationType.newProduct;
      default:
        return NotificationType.general;
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final String? relatedId; // e.g. orderId

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.general,
    this.relatedId,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    NotificationType? type,
    String? relatedId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type.name,
      'relatedId': relatedId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: docId,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      createdAt: parsedDate,
      isRead: map['isRead'] as bool? ?? false,
      type: NotificationType.fromString(map['type']?.toString()),
      relatedId: map['relatedId']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          createdAt == other.createdAt &&
          isRead == other.isRead &&
          type == other.type &&
          relatedId == other.relatedId;

  @override
  int get hashCode =>
      Object.hash(id, title, body, createdAt, isRead, type, relatedId);
}
