import '../../domain/entities/cart_item.dart';

sealed class CartState {
  const CartState();
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartLoaded extends CartState {
  final List<CartItem> items;
  const CartLoaded(this.items);

  bool get isEmpty => items.isEmpty;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
}

class CartError extends CartState {
  final String message;
  const CartError(this.message);
}
