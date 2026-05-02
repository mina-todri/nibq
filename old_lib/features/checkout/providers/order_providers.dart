import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/order_repository.dart';
import '../../../core/models/order_model.dart';
import '../../auth/providers/auth_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

/// Fetches a specific order. Marked autoDispose to ensure cache is cleared
/// when the user leaves the order details screen.
final orderByIdProvider = FutureProvider.autoDispose.family<OrderModel,
    String>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  try {
    return await repo.getOrderById(id);
  } catch (e) {
    throw Exception('الطلب غير موجود أو تم حذفه');
  }
});

/// Stream of orders for the currently authenticated user.
/// Recreates automatically when currentUserProvider changes.
final userOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.uid.isEmpty) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchOrdersForUser(user.uid);
});

/// 1. Added allOrdersProvider for Admin Dashboard with global visibility.
/// autoDispose removed to prevent stream cancellation during navigation.
final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).watchAllOrders();
});
