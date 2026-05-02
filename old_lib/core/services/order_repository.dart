// lib/core/services/order_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  /// Creates an order, validates per-variant stock, and decrements it atomically.
  /// Uses Firestore auto-generated IDs and returns the document ID.
  Future<String> createOrderWithStockCheck(OrderModel order) async {
    if (order.items.isEmpty) throw ArgumentError('Order has no items');
    if (order.userId.isEmpty) throw ArgumentError('Order has no userId');

    final orderDocRef = _orders.doc();
    final firestoreId = orderDocRef.id;
    final orderWithId = order.copyWith(id: firestoreId);

    await _firestore.runTransaction<void>((tx) async {
      // 1. Collect unique product refs
      final uniqueProductIds =
      orderWithId.items.map((i) => i.productId).toSet().toList();
      final productRefs = uniqueProductIds
          .map((id) => _firestore.collection('products').doc(id))
          .toList();

      // 2. Read all product docs and the order doc inside the transaction
      final productSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final ref in productRefs) {
        final snap = await tx.get(ref);
        productSnaps[ref.id] = snap;
      }
      final orderSnap = await tx.get(orderDocRef);
      if (orderSnap.exists) throw Exception('هذا الطلب موجود مسبقاً');

      // 3. Validate per-variant stock and price for every order item
      for (final item in orderWithId.items) {
        final snap = productSnaps[item.productId];
        if (snap == null || !snap.exists) {
          throw Exception('المنتج "${item.name}" لم يعد متاحاً');
        }

        final data = snap.data()!;
        final rawVariants = (data['variants'] as List?) ?? [];

        // Validate price matches current Firestore price
        validateItemPrice(data, item);

        if (item.selectedVariant.isNotEmpty &&
            item.selectedVariant != 'default') {
          final matchedVariant =
          findVariant(rawVariants, item.selectedVariant);
          if (matchedVariant == null) {
            throw Exception(
                'الخيار "${item.selectedVariant}" غير موجود في "${item.name}"');
          }
          final variantStock =
              (matchedVariant['stock'] as num?)?.toInt() ?? 0;
          if (variantStock < item.quantity) {
            throw Exception(
                'الكمية المتاحة من "${item.name}" (${item.selectedVariant}) هي $variantStock فقط');
          }
        }
      }

      // 4. Write the order
      tx.set(orderDocRef, {...orderWithId.toMap(), 'id': firestoreId});

      // 5. Decrement variant stock atomically
      for (final item in orderWithId.items) {
        if (item.selectedVariant.isEmpty || item.selectedVariant == 'default') {
          continue;
        }
        final snap = productSnaps[item.productId]!;
        final data = snap.data()!;
        final rawVariants =
        List<dynamic>.from((data['variants'] as List?) ?? []);

        tx.update(
          _firestore.collection('products').doc(item.productId),
          {
            'variants': _adjustVariantStock(
                rawVariants, item.selectedVariant, -item.quantity),
          },
        );
      }
    });

    return firestoreId;
  }

  Future<OrderModel> getOrderById(String id) async {
    final doc = await _orders.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw StateError('Order not found: $id');
    }
    return OrderModel.fromMap({...data, 'id': doc.id});
  }

  /// Cancels an order and RESTORES per-variant stock.
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

      final itemsRaw = (data['items'] as List?) ?? [];
      for (final raw in itemsRaw) {
        final item = Map<String, dynamic>.from(raw as Map);
        final productId = item['productId']?.toString() ?? '';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final selectedVariant = item['selectedVariant']?.toString() ?? '';

        if (productId.isEmpty || qty <= 0) continue;
        if (selectedVariant.isEmpty || selectedVariant == 'default') continue;

        final productRef = _firestore.collection('products').doc(productId);
        final productSnap = await tx.get(productRef);
        if (!productSnap.exists) continue;

        final productData = productSnap.data()!;
        final rawVariants =
        List<dynamic>.from((productData['variants'] as List?) ?? []);

        tx.update(productRef, {
          'variants': _adjustVariantStock(rawVariants, selectedVariant, qty),
        });
      }

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

  Stream<List<OrderModel>> watchAllOrders({int? limit}) {
    var query = _orders.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => OrderModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({'status': status.name});
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

  /// Finds a variant map by name from a raw Firestore variants list.
  /// Returns null if not found.
  static Map<String, dynamic>? findVariant(
      List<dynamic> rawVariants, String variantName) {
    for (final rv in rawVariants) {
      if (rv is Map && rv['name']?.toString() == variantName) {
        return Map<String, dynamic>.from(rv);
      }
    }
    return null;
  }

  static void validateItemPrice(Map<String, dynamic> productData, OrderItemModel item) {
    final rawVariants = (productData['variants'] as List?) ?? [];
    final expectedPrice = getExpectedPrice(productData, rawVariants, item.selectedVariant);
    const tolerance = 0.5;

    if ((item.price - expectedPrice).abs() > tolerance) {
      throw Exception(
          'سعر "${item.name}" تغير، يرجى تحديث السلة والمحاولة مرة أخرى');
    }
  }

  static double getExpectedPrice(
      Map<String, dynamic> productData, List<dynamic> rawVariants, String variantName) {
    if (variantName.isNotEmpty && variantName != 'default') {
      final variant = findVariant(rawVariants, variantName);
      if (variant != null && variant['price'] != null) {
        return (variant['price'] as num).toDouble();
      }
    }

    return (productData['price'] as num?)?.toDouble() ?? 0;
  }

  /// Returns a new variants list with the stock of [variantName] adjusted by [delta].
  /// Positive delta = increment (restore), negative delta = decrement.
  static List<dynamic> _adjustVariantStock(
      List<dynamic> rawVariants, String variantName, int delta) {
    return rawVariants.map((rv) {
      if (rv is Map && rv['name']?.toString() == variantName) {
        final currentStock = (rv['stock'] as num?)?.toInt() ?? 0;
        return {
          ...Map<String, dynamic>.from(rv),
          'stock': currentStock + delta,
        };
      }
      return rv;
    }).toList();
  }
}