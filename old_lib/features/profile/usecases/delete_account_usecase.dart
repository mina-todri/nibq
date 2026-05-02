import '../../../core/services/auth_service.dart';
import '../../../core/services/order_repository.dart';

class DeleteAccountUseCase {
  final AuthService _auth;
  final OrderRepository _orders;

  DeleteAccountUseCase({
    required AuthService auth,
    required OrderRepository orders,
  })  : _auth = auth,
        _orders = orders;

  Future<void> call({required String password}) async {
    final uid = _auth.currentUserId;
    if (uid == null) throw StateError('No authenticated user');
    await _orders.deleteOrdersForUser(uid);
    await _auth.deleteAccountWithPassword(password: password);
  }
}