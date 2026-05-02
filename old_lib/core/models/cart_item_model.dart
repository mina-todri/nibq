import 'product_model.dart';

// 1. Data Model (للحفظ في قاعدة البيانات فقط)
class CartItemEntity {
  final String productId;
  final String selectedVariant;
  final int quantity;

  const CartItemEntity({
    required this.productId,
    required this.selectedVariant,
    required this.quantity,
  });

  CartItemEntity copyWith({String? productId, String? selectedVariant, int? quantity}) {
    return CartItemEntity(
      productId: productId ?? this.productId,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'selectedVariant': selectedVariant,
      'quantity': quantity,
    };
  }

  factory CartItemEntity.fromMap(Map<String, dynamic> map) {
    return CartItemEntity(
      productId: map['productId']?.toString() ?? '',
      selectedVariant: map['selectedVariant']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

// 2. UI Model (للعرض في واجهة المستخدم)
class CartItem {
  final ProductModel product;
  final String selectedVariant;
  final int quantity;

  const CartItem({
    required this.product,
    required this.selectedVariant,
    required this.quantity,
  });

  CartItem copyWith({ProductModel? product, String? selectedVariant, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      quantity: quantity ?? this.quantity,
    );
  }
}