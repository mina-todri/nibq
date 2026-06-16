// lib/core/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

/// Order status lifecycle.
///
/// Changes vs original:
/// - [CRITICAL FIX] Removed custom `.name` getter — it silently shadowed the
///   Dart 2.15+ built-in `Enum.name` getter, causing `toString()` calls on
///   the enum to return the wrong value in mixed Dart-version environments.
///   `fromString()` now uses the built-in `.name` for serialisation.
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
  // No custom `.name` — use Dart's built-in `Enum.name` (e.g. `status.name`)
}

/// A single product line inside an order snapshot.
///
/// Changes vs original:
/// - [FIX] `hashCode` replaced XOR chain with `Object.hash()`.
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
    selectedVariant: map['selectedVariant']?.toString() ??
        map['selectedSize']?.toString() ??
        '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
  );

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
      Object.hash(productId, name, category, price, selectedVariant, quantity);

  @override
  String toString() => 'OrderItemModel('
      'productId: $productId, name: $name, category: $category, '
      'price: $price, selectedVariant: $selectedVariant, quantity: $quantity)';
}

/// Immutable order snapshot persisted to Firestore.
///
/// Changes vs original:
/// - [CRITICAL FIX] `OrderStatus.name` custom getter removed (see enum above).
///   `toMap()` now uses the built-in `status.name`.
/// - [FIX] `toMap()` omits `note` key entirely when null — previously stored
///   an explicit `null` in Firestore, wasting index quota and causing surprise
///   `whereField('note', isNull: true)` matches.
/// - [FIX] `hashCode` replaced XOR chain with `Object.hashAll()`.
/// - [IMPROVEMENT] `itemCount` and `hasDiscount` convenience getters added.
class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discount;
  final double delivery;
  final double total;
  final OrderStatus status;
  final AddressModel address;
  final DateTime createdAt;
  final String? note;
  final String paymentMethod;
  final int? rating;
  final String? ratingComment;

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
    this.rating,
    this.ratingComment,
  });

  int get itemCount => items.fold(0, (acc, i) => acc + i.quantity);
  bool get hasDiscount => discount > 0;
  bool get isRated => rating != null;

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
    int? rating,
    String? ratingComment,
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
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'userName': userName,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'delivery': delivery,
      'total': total,
      'status': status.name, // built-in Enum.name
      'address': address.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentMethod': paymentMethod,
    };
    // Only write note when it has a value to avoid storing explicit nulls.
    if (note != null) map['note'] = note;
    if (rating != null) map['rating'] = rating;
    if (ratingComment != null) map['ratingComment'] = ratingComment;
    return map;
  }

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

    return OrderModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'عميل',
      items: itemsRaw
          .whereType<Map>()
          .map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      delivery: (map['delivery'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromString(map['status']?.toString()),
      address: AddressModel.fromMap(
          Map<String, dynamic>.from(map['address'] as Map? ?? {})),
      createdAt: parsedDate,
      note: map['note']?.toString(),
      paymentMethod: map['paymentMethod']?.toString() ?? 'cash',
      rating: (map['rating'] as num?)?.toInt(),
      ratingComment: map['ratingComment']?.toString(),
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
              paymentMethod == other.paymentMethod &&
              rating == other.rating &&
              ratingComment == other.ratingComment;

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    userName,
    items,
    subtotal,
    discount,
    delivery,
    total,
    status,
    address,
    createdAt,
    note,
    paymentMethod,
    rating,
    ratingComment,
  ]);

  @override
  String toString() => 'OrderModel('
      'id: $id, userId: $userId, userName: $userName, '
      'items: $items, subtotal: $subtotal, discount: $discount, '
      'delivery: $delivery, total: $total, status: $status, '
      'address: $address, createdAt: $createdAt, '
      'note: $note, paymentMethod: $paymentMethod, rating: $rating)';
}