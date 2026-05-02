import 'package:nibq/core/models/cart_item_model.dart';
import 'package:nibq/core/models/product_model.dart';

class CheckoutValidationError implements Exception {
  final String message;
  const CheckoutValidationError(this.message);

  @override
  String toString() => message;
}

class ValidateCheckoutUseCase {
  final List<ProductModel> Function() getProducts;

  ValidateCheckoutUseCase({required this.getProducts});

  void call(List<CartItem> cartItems) {
    if (cartItems.isEmpty) {
      throw const CheckoutValidationError('السلة فارغة');
    }

    final products = getProducts();
    if (products.isEmpty) {
      throw const CheckoutValidationError('المنتجات غير متاحة حالياً');
    }

    for (final cartItem in cartItems) {
      final product = products.firstWhere(
        (p) => p.id == cartItem.product.id,
        orElse: () => throw CheckoutValidationError(
          'المنتج "${cartItem.product.name}" لم يعد متوفراً',
        ),
      );

      final priceMatch = _priceEquals(product.finalPrice, cartItem.product.finalPrice);
      if (!priceMatch) {
        throw CheckoutValidationError(
          'سعر "${cartItem.product.name}" تغير. يرجى تحديث السلة والمحاولة مرة أخرى',
        );
      }

      if (cartItem.selectedVariant == 'default' || cartItem.selectedVariant.isEmpty) {
        final totalStock = product.toMap()['variants'] as List? ?? [];
        final stock = totalStock.fold(
          0,
          (s, v) => s + ((v['stock'] as num?)?.toInt() ?? 0),
        );
        if (stock < cartItem.quantity) {
          throw CheckoutValidationError(
            'الكمية المتاحة لـ "${cartItem.product.name}" غير كافية ($stock متبقي)',
          );
        }
      } else {
        final rawVariants = product.toMap()['variants'] as List? ?? [];
        final variant = rawVariants.firstWhere(
          (v) => v['name'] == cartItem.selectedVariant,
          orElse: () => throw CheckoutValidationError(
            'الخيار "${cartItem.selectedVariant}" لـ "${cartItem.product.name}" لم يعد متوفراً',
          ),
        );
        final stock = (variant['stock'] as num?)?.toInt() ?? 0;
        if (stock < cartItem.quantity) {
          throw CheckoutValidationError(
            'الكمية المتاحة لـ "${cartItem.product.name}" (${cartItem.selectedVariant}) غير كافية ($stock متبقي)',
          );
        }
      }
    }
  }

  bool _priceEquals(double a, double b) {
    return (a - b).abs() < 0.01;
  }
}
