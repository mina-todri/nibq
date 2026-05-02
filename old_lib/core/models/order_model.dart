// lib/core/models/order_model.dart
// FIXES:
//   1. Added phone field to order (from delivery address)
//   2. createdAt stored as Timestamp (Firestore native) for correct
//      orderBy() queries — ISO string caused lexicographic sorting bugs
//   3. Added discount field to record applied discount amount
//   4. Added note and paymentMethod fields
//   5. Removed tax field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled;

  static OrderStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  String get name => toString().split('.').last;
}

class OrderItemModel {
  final String productId;
  final String name;
  final String category;
  final double price;
  final String selectedVariant;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.category,
    required this.price,
    required this.selectedVariant,
    required this.quantity,
  });

  String get formattedVariant {
    final hasVariant = selectedVariant.isNotEmpty && selectedVariant != 'default';
    return hasVariant ? '$selectedVariant × $quantity' : '× $quantity';
  }

  OrderItemModel copyWith({
    String? productId,
    String? name,
    String? category,
    double? price,
    String? selectedVariant,
    int? quantity,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemModel &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          name == other.name &&
          category == other.category &&
          price == other.price &&
          selectedVariant == other.selectedVariant &&
          quantity == other.quantity;

  @override
  int get hashCode =>
      productId.hashCode ^
      name.hashCode ^
      category.hashCode ^
      price.hashCode ^
      selectedVariant.hashCode ^
      quantity.hashCode;

  @override
  String toString() {
    return 'OrderItemModel(productId: $productId, name: $name, category: $category, price: $price, selectedVariant: $selectedVariant, quantity: $quantity)';
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'category': category,
        'price': price,
        'selectedVariant': selectedVariant,
        'quantity': quantity,
      };

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
        productId: map['productId']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        category: map['category']?.toString() ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        selectedVariant:
            map['selectedVariant']?.toString() ?? map['selectedSize']?.toString() ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discount;
  final double delivery;
  final double total;
  final OrderStatus status; // pending | confirmed | shipped | delivered | cancelled
  final AddressModel address;
  final DateTime createdAt;
  final String? note;
  final String paymentMethod;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.delivery,
    required this.total,
    required this.status,
    required this.address,
    required this.createdAt,
    this.note,
    this.paymentMethod = 'cash',
  });

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    List<OrderItemModel>? items,
    double? subtotal,
    double? discount,
    double? delivery,
    double? total,
    OrderStatus? status,
    AddressModel? address,
    DateTime? createdAt,
    String? note,
    String? paymentMethod,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      delivery: delivery ?? this.delivery,
      total: total ?? this.total,
      status: status ?? this.status,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          userName == other.userName &&
          items == other.items &&
          subtotal == other.subtotal &&
          discount == other.discount &&
          delivery == other.delivery &&
          total == other.total &&
          status == other.status &&
          address == other.address &&
          createdAt == other.createdAt &&
          note == other.note &&
          paymentMethod == other.paymentMethod;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      userName.hashCode ^
      items.hashCode ^
      subtotal.hashCode ^
      discount.hashCode ^
      delivery.hashCode ^
      total.hashCode ^
      status.hashCode ^
      address.hashCode ^
      createdAt.hashCode ^
      note.hashCode ^
      paymentMethod.hashCode;

  @override
  String toString() {
    return 'OrderModel(id: $id, userId: $userId, userName: $userName, items: $items, subtotal: $subtotal, discount: $discount, delivery: $delivery, total: $total, status: $status, address: $address, createdAt: $createdAt, note: $note, paymentMethod: $paymentMethod)';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'delivery': delivery,
        'total': total,
        'status': status.name,
        'address': address.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'note': note,
        'paymentMethod': paymentMethod,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final itemsRaw = (map['items'] as List?) ?? const [];

    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final subtotal = (map['subtotal'] as num?)?.toDouble() ?? 0;
    final discount = (map['discount'] as num?)?.toDouble() ?? 0;
    final delivery = (map['delivery'] as num?)?.toDouble() ?? 0;
    final total = (map['total'] as num?)?.toDouble() ?? 0;

    return OrderModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'عميل',
      items: itemsRaw
          .whereType<Map>()
          .map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: subtotal,
      discount: discount,
      delivery: delivery,
      total: total,
      status: OrderStatus.fromString(map['status']?.toString()),
      address: AddressModel.fromMap(
          Map<String, dynamic>.from(map['address'] as Map? ?? {})),
      createdAt: parsedDate,
      note: map['note']?.toString(),
      paymentMethod: map['paymentMethod']?.toString() ?? 'cash',
    );
  }
}
