// lib/core/services/order_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../constants/app_constants.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<String> createOrder(OrderModel order) async {
    final generatedId = AppConstants.generateOrderId();
    final ref = _orders.doc(generatedId);
    final orderWithId = order.copyWith(id: generatedId);
    await ref.set(orderWithId.toMap());
    return generatedId;
  }

  Future<void> createOrderWithStockCheck(OrderModel order) async {
    if (order.id.isEmpty) throw ArgumentError('Order ID cannot be empty');
    if (order.items.isEmpty) throw ArgumentError('Order has no items');
    if (order.userId.isEmpty) throw ArgumentError('Order has no userId');

    await _firestore.runTransaction((tx) async {
      final productRefs = order.items
          .map((i) => _firestore.collection('products').doc(i.productId))
          .toList();

      final productSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in productRefs) {
        productSnaps.add(await tx.get(ref));
      }

      final orderSnap = await tx.get(_orders.doc(order.id));

      if (orderSnap.exists) {
        throw Exception('هذا الطلب موجود مسبقاً');
      }

      for (var idx = 0; idx < order.items.length; idx++) {
        final item = order.items[idx];
        final snap = productSnaps[idx];

        if (!snap.exists) {
          throw Exception('المنتج "${item.name}" لم يعد متاحاً');
        }

        final product = ProductModel.fromMap(snap.data()!, item.productId);
        final liveStock = product.getStockForVariant(item.selectedVariant);

        if (liveStock < item.quantity) {
          throw Exception('الكمية المتاحة من "${item.name} - ${item.selectedVariant}" هي $liveStock فقط');
        }
      }

      tx.set(_orders.doc(order.id), {...order.toMap(), 'id': order.id});

      // Create Notification
      final notifRef = _firestore
          .collection('users')
          .doc(order.userId)
          .collection('notifications')
          .doc();
      
      tx.set(notifRef, {
        'title': 'تم استلام طلبك',
        'body': 'شكراً لتسوقك معنا! طلبك رقم ${order.id} قيد المراجعة الآن.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'orderStatus',
        'relatedId': order.id,
      });

      for (var idx = 0; idx < order.items.length; idx++) {
        final item = order.items[idx];
        final snap = productSnaps[idx];
        final product = ProductModel.fromMap(snap.data()!, item.productId);

        if (product.productVariants.isEmpty) {
          // Backward compatibility: no variants, use totalStock
          tx.update(productRefs[idx], {
            'totalStock': FieldValue.increment(-item.quantity),
            'stock': FieldValue.increment(-item.quantity), // maintain old key too
          });
        } else {
          // New variant system: find and update specific variant stock
          final updatedVariants = product.productVariants.map((v) {
            if (v.name == item.selectedVariant) {
              return v.copyWith(stock: v.stock - item.quantity).toMap();
            }
            return v.toMap();
          }).toList();

          tx.update(productRefs[idx], {
            'productVariants': updatedVariants,
            'totalStock': FieldValue.increment(-item.quantity),
          });
        }
      }
    });
  }

  Future<OrderModel> getOrderById(String id) async {
    final doc = await _orders.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw StateError('Order not found: $id');
    }
    return OrderModel.fromMap({...data, 'id': doc.id});
  }

  Future<void> cancelOrder(String orderId) async {
    await _firestore.runTransaction((tx) async {
      final orderRef = _orders.doc(orderId);
      final orderSnap = await tx.get(orderRef);

      if (!orderSnap.exists) throw Exception('الطلب غير موجود');

      final data = orderSnap.data()!;
      final status = OrderStatus.fromString(data['status']?.toString());
      if (status != OrderStatus.pending) {
        throw Exception('لا يمكن إلغاء الطلب بعد تأكيده');
      }

      await _updateStockForOrderItems(tx, data['items'] as List?, restore: true);
      tx.update(orderRef, {'status': OrderStatus.cancelled.name});
    });
  }

  Stream<List<OrderModel>> watchOrdersForUser(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => OrderModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Extension for Admins
  Stream<List<OrderModel>> watchAllOrders({int? limit}) {
    var query = _orders.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => OrderModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _firestore.runTransaction((tx) async {
      final orderRef = _orders.doc(orderId);
      final orderSnap = await tx.get(orderRef);

      if (!orderSnap.exists) throw Exception('الطلب غير موجود');

      final data = orderSnap.data()!;
      final oldStatus = OrderStatus.fromString(data['status']?.toString());

      if (oldStatus == newStatus) return;

      if (newStatus == OrderStatus.cancelled && oldStatus != OrderStatus.cancelled) {
        await _updateStockForOrderItems(tx, data['items'] as List?, restore: true);
      } else if (oldStatus == OrderStatus.cancelled && newStatus != OrderStatus.cancelled) {
        await _updateStockForOrderItems(tx, data['items'] as List?, restore: false);
      }

      tx.update(orderRef, {'status': newStatus.name});

      // Create Notification
      final userId = data['userId']?.toString() ?? '';
      if (userId.isNotEmpty) {
        final notifRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();
        
        String title = 'تحديث حالة الطلب';
        String body = 'تم تغيير حالة طلبك رقم $orderId إلى ${_statusText(newStatus)}';
        
        tx.set(notifRef, {
          'title': title,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'orderStatus',
          'relatedId': orderId,
        });
      }
    });
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'قيد الانتظار';
      case OrderStatus.confirmed: return 'تم التأكيد';
      case OrderStatus.shipped: return 'تم الشحن';
      case OrderStatus.delivered: return 'تم التوصيل';
      case OrderStatus.cancelled: return 'تم الإلغاء';
    }
  }

  Future<void> _updateStockForOrderItems(
    Transaction tx,
    List<dynamic>? itemsRaw, {
    required bool restore,
  }) async {
    final items = (itemsRaw ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (items.isEmpty) return;

    // 1. Group items by product to handle multiple items/variants of same product
    final itemsByProduct = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final pid = item['productId']?.toString() ?? '';
      if (pid.isNotEmpty) {
        itemsByProduct.putIfAbsent(pid, () => []).add(item);
      }
    }

    // 2. ALL READS FIRST: Fetch all unique products in one go (before any writes)
    final productSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final pid in itemsByProduct.keys) {
      productSnaps[pid] = await tx.get(_firestore.collection('products').doc(pid));
    }

    // 3. ALL WRITES AFTER: Apply updates per product
    for (final pid in itemsByProduct.keys) {
      final snap = productSnaps[pid];
      if (snap == null || !snap.exists) continue;

      final itemsForThisProduct = itemsByProduct[pid]!;
      var product = ProductModel.fromMap(snap.data()!, pid);

      // Accumulate all stock changes for this product
      int totalDiff = 0;
      List<ProductVariant> updatedVariants = List.from(product.productVariants);

      for (final item in itemsForThisProduct) {
        final variantName = item['selectedVariant']?.toString() ?? '';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final diff = restore ? qty : -qty;
        totalDiff += diff;

        if (updatedVariants.isNotEmpty) {
          updatedVariants = updatedVariants.map((v) {
            if (v.name == variantName) {
              return v.copyWith(stock: v.stock + diff);
            }
            return v;
          }).toList();
        }
      }

      final updateData = <String, dynamic>{
        'totalStock': product.totalStock + totalDiff,
      };

      if (product.productVariants.isEmpty) {
        updateData['stock'] = product.totalStock + totalDiff;
      } else {
        updateData['productVariants'] = updatedVariants.map((v) => v.toMap()).toList();
      }

      tx.update(_firestore.collection('products').doc(pid), updateData);
    }
  }

  Future<void> deleteOrdersForUser(String userId) async {
    final q = await _orders.where('userId', isEqualTo: userId).get();
    if (q.docs.isEmpty) return;
    const batchSize = 400;
    for (var i = 0; i < q.docs.length; i += batchSize) {
      final batch = _firestore.batch();
      for (final d in q.docs.skip(i).take(batchSize)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}
