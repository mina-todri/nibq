import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _dataSource;

  const CartRepositoryImpl(this._dataSource);

  @override
  Stream<List<CartItem>> watchItems(String userId) =>
      _dataSource.watchItems(userId);

  @override
  Future<void> setItem(String userId, CartItem item) =>
      _dataSource.setItem(userId, item);

  @override
  Future<void> removeItem(String userId, String itemId) =>
      _dataSource.removeItem(userId, itemId);

  @override
  Future<void> clearCart(String userId, List<CartItem> items) =>
      _dataSource.clearCart(userId, items);
}